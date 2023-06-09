//
//  Created by Mike Gerasymenko <mike@gera.cx>
//

import Foundation
import XcodeProj
import PathKit
import Workspace
import Logger
import Git

extension PBXBuildFile {
    func path(projectFolder: Path) -> Path? {
        
        if let path = self.file?.path {
            if let parent = self.file?.parent?.path {
                return projectFolder + parent + path
            }
            else {
                return projectFolder + path
            }
        }
        else {
            Logger.warning("File without path: \(self)")
            return nil
        }
    }
}

extension WorkspaceInfo {
    public static func parseWorkspace(at path: Path) throws -> WorkspaceInfo {
        guard path.extension == "xcworkspace" else {
            return try WorkspaceInfo.parseProject(at: path)
        }
        
        let workspace = try XCWorkspace(path: path)
        
        let workspaceDefinitionPath = path + "contents.xcworkspacedata"
        
        let (packageWorkspaceInfo, packages) = try parsePackages(in: path)
        
        var resultDependencies: DependencyGraph = packageWorkspaceInfo.dependencyStructure
        var files: [TargetIdentity: Set<Path>] = packageWorkspaceInfo.files
        
        let allProjects = try workspace.allProjects(basePath: path.parent())
        
        try allProjects.forEach { (project, projectPath) in
            let newDependencies = try parseProject(from: project,
                                                   path: projectPath,
                                                   packages: packages,
                                                   allProjects: allProjects)
            resultDependencies = resultDependencies.merging(with: newDependencies.dependencyStructure)
            
            let projectDefinitionPath = projectPath + "project.pbxproj"
            
            var newFiles = [TargetIdentity: Set<Path>]()
            
            // Append project and workspace paths, as they might change the project compilation
            newDependencies.files.forEach { (target, files) in
                newFiles[target] = files.union([workspaceDefinitionPath, projectDefinitionPath])
            }
            
            files = files.merging(with: newFiles)
            
        }
        
        return WorkspaceInfo(files: files, dependencyStructure: resultDependencies)
    }
    
    static func findPackages(in path: Path) throws -> [String: PackageMetadata] {
        return try Array(Git(path: path).find(pattern: "/Package.swift")).concurrentMap { path in
            return try? PackageMetadata.parse(at: path)
        }.compactMap { $0 }.reduce([String: PackageMetadata](), { partialResult, new in
            var result = partialResult
            result[new.name] = new
            return result
        })
    }
    
    static func parsePackages(in path: Path) throws -> (WorkspaceInfo, [String: PackageMetadata]) {
        
        var dependsOn: [TargetIdentity: Set<TargetIdentity>] = [:]
        var files: [TargetIdentity: Set<Path>] = [:]
        
        let packages = try findPackages(in: path)
        
        try packages.forEach { (name, metadata) in
            metadata.dependsOn.forEach { dependency in
                dependsOn.insert(metadata.targetIdentity(), dependOn: dependency)
            }
            let searchPath = Path(metadata.path.parent().string.replacingOccurrences(of: try "\(Git(path: path).repoRoot().string)/", with: ""))
            
            files[metadata.targetIdentity()] = try Git(path: path).find(pattern: "\(searchPath)/")
        }
        
        return (WorkspaceInfo(files: files, dependencyStructure: DependencyGraph(dependsOn: dependsOn)), packages)
    }
    
    static func parseProject(from project: XcodeProj,
                             path: Path,
                             packages: [String: PackageMetadata],
                             allProjects: [(XcodeProj, Path)]) throws -> WorkspaceInfo {
        
        var dependsOn: [TargetIdentity: Set<TargetIdentity>] = [:]
        var files: [TargetIdentity: Set<Path>] = [:]
        
        try project.pbxproj.nativeTargets.forEach { target in
            let targetIdentity = TargetIdentity(projectPath: path, target: target)
            // Target dependencies
            target.dependencies.forEach { dependency in
                guard let name = dependency.target?.name else {
                    Logger.warning("Target without name: \(dependency)")
                    return
                }
                dependsOn.insert(targetIdentity,
                                dependOn: TargetIdentity(projectPath: path, targetName: name))
            }
            
            // Package dependencies
            target.packageProductDependencies.forEach { packageDependency in
                let package = packageDependency.productName
                guard let packageMetadata = packages[package] else {
                    Logger.warning("Package \(package) not found")
                    return
                }
                dependsOn.insert(targetIdentity,
                                 dependOn: TargetIdentity.swiftPackage(path: packageMetadata.path, name: package))
            }
            
            // Source Files
            var filesPaths = Set(try target.sourcesBuildPhase()?.files?.compactMap { file in
                return file.path(projectFolder: path.parent())
            } ?? [])
            
            // Resources
            filesPaths = filesPaths.union(Set(try target.resourcesBuildPhase()?.files?.compactMap { file in
                return file.path(projectFolder: path.parent())
            } ?? []))
            
            try target.frameworksBuildPhase()?.files?.forEach { file in
                allProjects.forEach { (proj, projPath) in
                    proj.pbxproj.nativeTargets.forEach { someTarget in
                        if someTarget.productNameWithExtension() == file.file?.path {
                            dependsOn.insert(targetIdentity,
                                             dependOn: TargetIdentity(projectPath: projPath, targetName: someTarget.name))
                        }
                    }
                }
            }
            
            var subfolders = Set<Path>()
            
            try filesPaths.forEach { path in
                if path.isDirectory {
                    subfolders = subfolders.union(Set(try path.recursiveChildren()))
                }
            }
            filesPaths = filesPaths.union(subfolders)
            files[targetIdentity] = filesPaths
        }
        
        return WorkspaceInfo(files: files, dependencyStructure: DependencyGraph(dependsOn: dependsOn))
    }
    
    public static func parseProject(at path: Path) throws -> WorkspaceInfo {
        
        let (packageWorkspaceInfo, packages) = try parsePackages(in: path)
        
        let xcodeproj = try XcodeProj(path: path)
        
        let projectInfo = try parseProject(from: xcodeproj, path: path, packages: packages, allProjects: [])
        
        return WorkspaceInfo(files: projectInfo.files.merging(with: packageWorkspaceInfo.files),
                             dependencyStructure: projectInfo.dependencyStructure.merging(with: packageWorkspaceInfo.dependencyStructure))
    }
}

