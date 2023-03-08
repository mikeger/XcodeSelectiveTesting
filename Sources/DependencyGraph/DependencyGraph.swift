//
//  Created by Mike Gerasymenko <mike@gera.cx>
//

import Foundation
import XcodeProj
import PathKit
import Workspace
import Logger

extension Path {
    func relative(to rootPath: Path) -> Path {
        return Path(rootPath.url.appendingPathComponent(self.string).path)
    }
}

extension XCWorkspace {
    func allProjects(basePath: Path) throws -> [(XcodeProj, Path)] {
        try XCWorkspace.allProjects(from: self.data.children, basePath: basePath)
    }
    
    private static func allProjects(from group: [XCWorkspaceDataElement], basePath: Path) throws -> [(XcodeProj, Path)] {
        var projects: [(XcodeProj, Path)] = []
        
        try group.forEach { element in
            switch element {
            case .file(let file):
                switch file.location {
                case .absolute(let path):
                    let resultingPath = Path(path).relative(to: basePath)
                    projects.append((try XcodeProj(path: resultingPath), resultingPath))
                case .group(let path):
                    let resultingPath = Path(path).relative(to: basePath)
                    projects.append((try XcodeProj(path: resultingPath), resultingPath))
                case .current(let path):
                    let resultingPath = Path(path).relative(to: basePath)
                    projects.append((try XcodeProj(path: resultingPath), resultingPath))
                case .developer(let path):
                    let resultingPath = Path(path).relative(to: basePath)
                    projects.append((try XcodeProj(path: resultingPath), resultingPath))
                case .container(let path):
                    let resultingPath = Path(path).relative(to: basePath)
                    projects.append((try XcodeProj(path: resultingPath), resultingPath))
                case .other(_, let path):
                    let resultingPath = Path(path).relative(to: basePath)
                    projects.append((try XcodeProj(path: resultingPath), resultingPath))
                }
                
            case .group(let element):
                projects.append(contentsOf: try XCWorkspace.allProjects(from: element.children, basePath: basePath))
            }
        }
        
        return projects
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
        
        var dependencyStructure = DependencyGraph(dependsOn: [:])
        var files: [TargetIdentity: Set<Path>] = [:]
        
        try project.pbxproj.nativeTargets.forEach { target in
            let targetIdentity = TargetIdentity(projectPath: path, target: target)
            // Target dependencies
            target.dependencies.forEach { dependency in
                guard let name = dependency.target?.name else {
                    Logger.warning("Warning: Target without name: \(dependency)")
                    return
                }
                dependencyStructure.insert(targetIdentity,
                                           dependOn: TargetIdentity(projectPath: path, targetName: name))
            }
            
            // Package dependencies
            target.packageProductDependencies.forEach { packageDependency in
                // TODO: Targets depending on SPM packages are not implemented ATM
                Logger.message("PACKAGE: \(packageDependency.package) \(packageDependency.productName)")
            }
            
            // Source Files
            var filesPaths = Set<Path>()
            
            filesPaths = filesPaths.union(Set(try target.sourcesBuildPhase()?.files?.compactMap { file in
                if let path = file.file?.path {
                    return Path(path)
                }
                else {
                    Logger.warning("Warning: File without path: \(file)")
                    return nil
                }
            } ?? []))
            
            // Resources
            filesPaths = filesPaths.union(Set(try target.resourcesBuildPhase()?.files?.compactMap { file in
                if let path = file.file?.path {
                    return Path(path)
                }
                else {
                    Logger.warning("Warning: File without path: \(file)")
                    return nil
                }
            } ?? []))
            
            try target.frameworksBuildPhase()?.files?.forEach { file in
                // TODO: Make targets depend on targets producing their dependencies
                Logger.message("frameworksBuildPhase: \(file.file?.path) \(file.product?.productName)")
            }
            
            files[targetIdentity] = filesPaths
        }
        
        return WorkspaceInfo(files: files, dependencyStructure: dependencyStructure)
    }
    
    public static func parseProject(at path: Path) throws -> WorkspaceInfo {
        let xcodeproj = try XcodeProj(path: path)
        
        return try parseProject(from: xcodeproj, path: path)
    }
}

