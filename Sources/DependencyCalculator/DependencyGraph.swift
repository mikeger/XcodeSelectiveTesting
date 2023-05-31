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
            Logger.warning("Warning: File without path: \(self)")
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
            files = files.merging(with: newDependencies.files)
        }
        
        return WorkspaceInfo(files: files, dependencyStructure: resultDependencies)
    }
    
    static func findPackages(in path: Path) throws -> [String: PackageMetadata] {
        var result: [String: PackageMetadata] = [:]
        try GitFind.findWithGit(pattern: "/Package.swift", path: path).forEach { path in
            let packageMetadata = try PackageMetadata.parse(at: path)
            result[packageMetadata.name] = packageMetadata
        }
        
        return result
    }
    
    static func parsePackages(in path: Path) throws -> (WorkspaceInfo, [String: PackageMetadata]) {
        
        var dependsOn: [TargetIdentity: Set<TargetIdentity>] = [:]
        var files: [TargetIdentity: Set<Path>] = [:]
        
        let packages = try findPackages(in: path)
        
        try packages.forEach { (name, metadata) in
            metadata.dependsOn.forEach { dependency in
                dependsOn.insert(metadata.targetIdentity(), dependOn: dependency)
            }
            let searchPath = Path(metadata.path.parent().string.replacingOccurrences(of: try "\(GitFind.repoRoot(at: path).string)/", with: ""))
            
            files[metadata.targetIdentity()] = try GitFind.findWithGit(pattern: "\(searchPath)/", path: path)
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
                    Logger.warning("Warning: Target without name: \(dependency)")
                    return
                }
                dependsOn.insert(targetIdentity,
                                dependOn: TargetIdentity(projectPath: path, targetName: name))
            }
            
            // Package dependencies
            target.packageProductDependencies.forEach { packageDependency in
                let package = packageDependency.productName
                guard let packageMetadata = packages[package] else {
                    Logger.warning("Warning: Package \(package) not found")
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

