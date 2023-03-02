import Foundation
import XcodeProj
import PathKit

extension XCWorkspace {
    func allProjects() throws -> [XcodeProj] {
        try XCWorkspace.allProjects(from: self.data.children)
    }
    
    private static func allProjects(from group: [XCWorkspaceDataElement]) throws -> [XcodeProj] {
        var projects: [XcodeProj] = []
        
        try group.forEach { element in
            switch element {
            case .file(let file):
                switch file.location {
                case .absolute(let path):
                    projects.append(try XcodeProj(path: Path(path)))
                case .group(let path):
                    projects.append(try XcodeProj(path: Path(path)))
                case .current(let path):
                    projects.append(try XcodeProj(path: Path(path)))
                case .developer(let path):
                    projects.append(try XcodeProj(path: Path(path)))
                case .container(let path):
                    projects.append(try XcodeProj(path: Path(path)))
                case .other(_, let path):
                    projects.append(try XcodeProj(path: Path(path)))
                }
                
            case .group(let element):
                projects.append(contentsOf: try XCWorkspace.allProjects(from: element.children))
            }
        }
        
        return projects
    }
}

struct DependencyStructure {
    private var map: [TargetIdentity: Set<TargetIdentity>]
    
    func allTargets() -> [TargetIdentity] {
        return Array(map.keys)
    }
    
    func dependencies(for target: TargetIdentity) -> Set<TargetIdentity> {
        return map[target] ?? Set()
    }
    
    mutating func insert(_ target: TargetIdentity, dependOn: TargetIdentity) {
        var set = map[target] ?? Set<TargetIdentity>()
        
        set.insert(dependOn)
        map[target] = set
    }
    
    private func merge(with other: DependencyStructure) -> DependencyStructure {
        var map = self.map
        
        other.map.keys.forEach { key in
            let set = map[key] ?? Set<TargetIdentity>()
            
            map[key] = set.union(other.map[key]!)
        }
        
        return DependencyStructure(map: map)
    }
    
    static func parseWorkspace(at path: Path) throws -> DependencyStructure {
        let workspace = try XCWorkspace(path: path)
        
        var result: DependencyStructure = DependencyStructure(map: [:])
        
        try workspace.allProjects().forEach { project in
            let newDependencies = try parseProject(from: project, path: path)
            result = result.merge(with: newDependencies)
        }
        
        return result
    }
    
    static func parseProject(from project: XcodeProj, path: Path) throws -> DependencyStructure {
        
        var dependencyStructure = DependencyStructure(map: [:])
        
        project.pbxproj.nativeTargets.forEach { target in
            // Target dependencies
            target.dependencies.forEach { dependency in
                dependencyStructure.insert(TargetIdentity(projectPath: path, target: target),
                                           dependOn: TargetIdentity(projectPath: path, target: dependency))
            }
            
            // Package dependencies
            target.packageProductDependencies.forEach { packageDependency in
                print(": \(packageDependency.package?.repositoryURL) \(packageDependency.productName)")
            }
        }
        
        return dependencyStructure
    }
    
    static func parseProject(at path: Path) throws -> DependencyStructure {
        let xcodeproj = try XcodeProj(path: path)
        
        return try parseProject(from: xcodeproj, path: path)
    }
}
