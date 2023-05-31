//
//  Created by Mike Gerasymenko <mike@gera.cx>
//

import Foundation
import XcodeProj
import PathKit
import Workspace
import Logger

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
        
        var resultDependencies: DependencyGraph = DependencyGraph(dependsOn: [:])
        var files: [TargetIdentity: Set<Path>] = [:]
        
        try workspace.allProjects(basePath: path.parent()).forEach { (project, projectPath) in
            let newDependencies = try parseProject(from: project, path: projectPath)
            resultDependencies = resultDependencies.merge(with: newDependencies.dependencyStructure)
            files = files.merging(with: newDependencies.files)
        }
        
        return WorkspaceInfo(files: files, dependencyStructure: resultDependencies)
    }
    
    public static func parseProject(from project: XcodeProj, path: Path) throws -> WorkspaceInfo {
        
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
                // TODO: Targets depending on SPM packages are not implemented ATM
                Logger.message("PACKAGE: \(String(describing: packageDependency.package)) \(packageDependency.productName)")
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
                // TODO: Make targets depend on targets producing their dependencies
                Logger.message("frameworksBuildPhase: \(String(describing: file.file?.path)) \(String(describing: file.product?.productName))")
            }
            
            files[targetIdentity] = filesPaths
        }
        
        return WorkspaceInfo(files: files, dependencyStructure: DependencyGraph(dependsOn: dependsOn))
    }
    
    public static func parseProject(at path: Path) throws -> WorkspaceInfo {
        let xcodeproj = try XcodeProj(path: path)
        
        return try parseProject(from: xcodeproj, path: path)
    }
}

