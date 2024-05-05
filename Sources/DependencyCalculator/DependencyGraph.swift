//
//  Created by Mike Gerasymenko <mike@gera.cx>
//

import Foundation
import Git
import PathKit
import SelectiveTestLogger
import Workspace
import XcodeProj

extension PBXBuildFile {
    func path(projectFolder: Path) -> Path? {
        if let path = file?.path {
            var intermediatePath = Path()

            var parent = file?.parent

            while parent?.path != nil {
                if let parentPath = parent?.path {
                    intermediatePath = Path(parentPath) + intermediatePath
                }
                parent = parent?.parent
            }

            return projectFolder + intermediatePath + path
        } else {
            Logger.warning("File without path: self=\(self), \n self.file=\(String(describing: file)), \n self.product=\(String(describing: product))")
            return nil
        }
    }
}

extension PBXNativeTarget {
    func canProduce(_ productName: String) -> Bool {
        if productNameWithExtension()?.lowercased() == productName.lowercased() {
            return true
        }

        guard let ext = productType?.fileExtension else {
            return false
        }
        // productNameWithExtension() is not always returning a correct name for the framework.
        // Assume a tragetName.extension is a correct framework name, as a last resort
        return "\(name).\(ext)".lowercased() == productName.lowercased()
    }
}

extension WorkspaceInfo {
    public static func parseWorkspace(at path: Path,
                                      config: WorkspaceInfo.AdditionalConfig? = nil,
                                      exclude: [String]) throws -> WorkspaceInfo
    {
        let includeRootPackage = !Set(["xcworkspace", "xcodeproj"]).contains(path.extension)

        var (packageWorkspaceInfo, packages) = try parsePackages(in: path, includeRootPackage: includeRootPackage, exclude: exclude)

        var resultDependencies = packageWorkspaceInfo.dependencyStructure
        var files = packageWorkspaceInfo.files
        var folders = packageWorkspaceInfo.folders
        var candidateTestPlan = packageWorkspaceInfo.candidateTestPlan

        let allProjects: [(XcodeProj, Path)]
        var workspaceDefinitionPath: Path? = nil
        if path.extension == "xcworkspace" {
            let workspace = try XCWorkspace(path: path)

            workspaceDefinitionPath = path + "contents.xcworkspacedata"
            allProjects = try workspace.allProjects(basePath: path.parent())
        } else if path.extension == "xcodeproj" {
            allProjects = try [(XcodeProj(path: path), path)]
        } else {
            allProjects = []
        }

        try allProjects.forEach { project, projectPath in
            let newDependencies = try parseProject(from: project,
                                                   path: projectPath,
                                                   packages: &packages,
                                                   allProjects: allProjects)
            resultDependencies = resultDependencies.merging(with: newDependencies.dependencyStructure)

            let projectDefinitionPath = projectPath + "project.pbxproj"

            var newFiles = [TargetIdentity: Set<Path>]()

            // Append project and workspace paths, as they might affect the project compilation
            for (target, files) in newDependencies.files {
                if let workspaceDefinitionPath {
                    newFiles[target] = files.union([workspaceDefinitionPath, projectDefinitionPath])
                } else {
                    newFiles[target] = files.union([projectDefinitionPath])
                }
            }

            files = files.merging(with: newFiles)
            folders = folders.merging(with: newDependencies.folders)
            if candidateTestPlan == nil {
                candidateTestPlan = newDependencies.candidateTestPlan
            }
        }

        let workspaceInfo = WorkspaceInfo(files: files,
                                          folders: folders,
                                          dependencyStructure: resultDependencies,
                                          candidateTestPlan: candidateTestPlan)
        if let config {
            // Process additional config
            return processAdditional(config: config, workspaceInfo: workspaceInfo)
        } else {
            return workspaceInfo
        }
    }

    static func processAdditional(config: WorkspaceInfo.AdditionalConfig,
                                  workspaceInfo: WorkspaceInfo) -> WorkspaceInfo
    {
        var files = workspaceInfo.files
        var folders = workspaceInfo.folders
        var resultDependencies = workspaceInfo.dependencyStructure
        let allTargets = Array(resultDependencies.allTargets()).toDictionary(path: \.configIdentity)

        for (targetName, dependOnTargets) in config.dependencies {
            guard let target = allTargets[targetName] else {
                Logger.error("Config: Cannot resolve \(targetName) to any known target")
                continue
            }
            for dependOnTargetName in dependOnTargets {
                guard let targetDependOn = allTargets[dependOnTargetName] else {
                    Logger.error("Config: Cannot resolve \(dependOnTargetName) to any known target")
                    continue
                }

                let newDependency = DependencyGraph(dependsOn: [target: Set([targetDependOn])])

                resultDependencies = resultDependencies.merging(with: newDependency)
            }
        }

        for (targetName, filesToAdd) in config.targetsFiles {
            guard let target = allTargets[targetName] else {
                Logger.error("Config: Cannot resolve \(targetName) to any known target")
                continue
            }

            for filePath in filesToAdd {
                let path = Path(filePath).absolute()

                guard path.exists else {
                    Logger.error("Config: Path \(path) does not exist")
                    continue
                }

                if path.isDirectory {
                    folders[path] = target
                } else {
                    var filesForTarget = files[target] ?? Set<Path>()
                    filesForTarget.insert(path)
                    files[target] = filesForTarget
                }
            }
        }

        return WorkspaceInfo(files: files,
                             folders: folders,
                             dependencyStructure: resultDependencies,
                             candidateTestPlan: workspaceInfo.candidateTestPlan)
    }

    static func findPackages(in path: Path,
                             includeRootPackage: Bool,
                             exclude: [String]) throws -> [PackageTargetMetadata]
    {
        var allPackages = try Git(path: path).find(pattern: "/Package.swift")
        if includeRootPackage {
            allPackages.insert(path + "Package.swift")
        }

        allPackages = allPackages.filter { packagePath in
            exclude.first { oneExclude in
                packagePath.string.contains(oneExclude)
            } == nil
        }

        return Array(allPackages).concurrentMap { path in
            try? PackageTargetMetadata.parse(at: path.parent())
        }.compactMap { $0 }.reduce([PackageTargetMetadata]()) { partialResult, new in
            var result = partialResult
            result.append(contentsOf: new)
            return result
        }
    }

    static func parsePackages(in path: Path,
                              includeRootPackage: Bool,
                              exclude: [String]) throws -> (WorkspaceInfo, [PackageTargetMetadata])
    {
        var dependsOn: [TargetIdentity: Set<TargetIdentity>] = [:]
        var folders: [Path: TargetIdentity] = [:]
        var files: [TargetIdentity: Set<Path>] = [:]
        let packages = try findPackages(in: path, includeRootPackage: includeRootPackage, exclude: exclude)

        for metadata in packages {
            for dependency in metadata.dependsOn {
                dependsOn.insert(metadata.targetIdentity(), dependOn: dependency)
            }

            for affectedByPath in metadata.affectedBy {
                guard affectedByPath.exists else {
                    Logger.warning("Path \(affectedByPath) is mentioned from package at \(metadata.path) but does not exist")
                    continue
                }

                if affectedByPath.isDirectory {
                    folders[affectedByPath] = metadata.targetIdentity()
                } else {
                    var filesForTarget = files[metadata.targetIdentity()] ?? Set()
                    filesForTarget.insert(affectedByPath)
                    files[metadata.targetIdentity()] = filesForTarget
                }
            }
        }

        return (WorkspaceInfo(files: files,
                              folders: folders,
                              dependencyStructure: DependencyGraph(dependsOn: dependsOn),
                              candidateTestPlan: nil), packages)
    }

    static func parseProject(from project: XcodeProj,
                             path: Path,
                             packages: inout [PackageTargetMetadata],
                             allProjects: [(XcodeProj, Path)]) throws -> WorkspaceInfo
    {
        var dependsOn: [TargetIdentity: Set<TargetIdentity>] = [:]
        var files: [TargetIdentity: Set<Path>] = [:]
        var folders: [Path: TargetIdentity] = [:]
        var candidateTestPlan: String? = nil

        var packagesByName: [String: PackageTargetMetadata] = packages.toDictionary(path: \.name)
        let targetsByName = project.pbxproj.nativeTargets.toDictionary(path: \.name)

        project.pbxproj.rootObject?.localPackages.forEach { localPackage in
            let absolutePath = path.parent() + localPackage.relativePath

            guard let newPackages = try? PackageTargetMetadata.parse(at: absolutePath) else {
                Logger.warning("Cannot find local package at \(absolutePath)")
                return
            }
            for package in newPackages {
                packagesByName[package.name] = package
                packages.append(package)
            }
        }

        try project.pbxproj.nativeTargets.forEach { target in
            let targetIdentity = TargetIdentity.project(path: path, target: target)
            // Target dependencies
            for dependency in target.dependencies {
                guard let name = dependency.target?.name else {
                    Logger.warning("Target without name: \(dependency)")
                    continue
                }

                if let dependencyTarget = targetsByName[name] {
                    dependsOn.insert(targetIdentity,
                                     dependOn: TargetIdentity.project(path: path, target: dependencyTarget))
                } else {
                    Logger.warning("Unknown target: \(name)")
                    dependsOn.insert(targetIdentity,
                                     dependOn: TargetIdentity.project(path: path, targetName: name, testTarget: false))
                }
            }

            // Package dependencies
            for packageDependency in target.packageProductDependencies {
                let package = packageDependency.productName
                guard let packageMetadata = packagesByName[package] else {
                    Logger.warning("Package \(package) not found")
                    continue
                }
                dependsOn.insert(targetIdentity,
                                 dependOn: packageMetadata.targetIdentity())
            }

            // Source Files
            var filesPaths = try Set(target.sourcesBuildPhase()?.files?.compactMap { file in
                file.path(projectFolder: path.parent())
            } ?? [])

            // Resources
            filesPaths = try filesPaths.union(Set(target.resourcesBuildPhase()?.files?.compactMap { file in
                file.path(projectFolder: path.parent())
            } ?? []))

            // Establish dependencies based on linked frameworks build phase
            try target.frameworksBuildPhase()?.files?.forEach { file in
                guard let path = file.file?.path else {
                    return
                }

                for (proj, projPath) in allProjects {
                    for someTarget in proj.pbxproj.nativeTargets {
                        if someTarget.canProduce(path) {
                            dependsOn.insert(targetIdentity,
                                             dependOn: TargetIdentity.project(path: projPath, target: someTarget))
                        }
                    }
                }
            }

            for path in filesPaths {
                if path.isDirectory {
                    folders[path] = targetIdentity
                }
            }
            files[targetIdentity] = filesPaths
        }

        // Find existing test plans
        project.sharedData?.schemes.forEach { scheme in
            scheme.testAction?.testPlans?.forEach { plan in
                candidateTestPlan = plan.reference.replacingOccurrences(of: "container:", with: "")
            }
        }

        return WorkspaceInfo(files: files,
                             folders: folders,
                             dependencyStructure: DependencyGraph(dependsOn: dependsOn),
                             candidateTestPlan: candidateTestPlan)
    }
}
