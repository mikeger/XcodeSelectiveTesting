import Foundation
import XcodeProj
import PathKit

extension Dictionary where Key == TargetIdentity, Value == Set<Path> {
    func merging(with other: Self) -> Self {
        self.merging(other, uniquingKeysWith: { first, second in
            first.union(second)
        })
    }
}

struct WorkspaceInfo {
    let files: [TargetIdentity: Set<Path>]
    let dependencyStructure: DependencyStructure
    
    private func merge(with other: WorkspaceInfo) -> WorkspaceInfo {
        let dependencyStructure = dependencyStructure.merge(with: other.dependencyStructure)
        
        return WorkspaceInfo(files: files.merging(with: other.files), dependencyStructure: dependencyStructure)
    }
}

extension WorkspaceInfo {
    static func parseWorkspace(at path: Path) throws -> WorkspaceInfo {
        let workspace = try XCWorkspace(path: path)
        
        var resultDependencies: DependencyStructure = DependencyStructure(dependsOn: [:])
        var files: [TargetIdentity: Set<Path>] = [:]
        
        try workspace.allProjects(basePath: path.parent()).forEach { (project, projectPath) in
            let newDependencies = try parseProject(from: project, path: projectPath)
            resultDependencies = resultDependencies.merge(with: newDependencies.dependencyStructure)
            files = files.merging(with: newDependencies.files)
        }
        
        return WorkspaceInfo(files: files, dependencyStructure: resultDependencies)
    }
    
    static func parseProject(from project: XcodeProj, path: Path) throws -> WorkspaceInfo {
        
        var dependencyStructure = DependencyStructure(dependsOn: [:])
        var files: [TargetIdentity: Set<Path>] = [:]
        
        try project.pbxproj.nativeTargets.forEach { target in
            let targetIdentity = TargetIdentity(projectPath: path, target: target)
            // Target dependencies
            target.dependencies.forEach { dependency in
                guard let name = dependency.target?.name else {
                    print("Target without name: \(dependency)")
                    return
                }
                dependencyStructure.insert(targetIdentity,
                                           dependOn: TargetIdentity(projectPath: path, targetName: name))
            }
            
            // Package dependencies
            target.packageProductDependencies.forEach { packageDependency in
                print("PACKAGE: \(packageDependency.package) \(packageDependency.productName)")
            }
            
            // Files
            files[targetIdentity] = Set(try target.sourceFiles().compactMap { file in
                if let path = file.path {
                    return Path(path)
                }
                else {
                    return nil
                }
            })
        }
        
        return WorkspaceInfo(files: files, dependencyStructure: dependencyStructure)
    }
    
    static func parseProject(at path: Path) throws -> WorkspaceInfo {
        let xcodeproj = try XcodeProj(path: path)
        
        return try parseProject(from: xcodeproj, path: path)
    }
}

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

struct DependencyStructure {
    private var dependsOn: [TargetIdentity: Set<TargetIdentity>]
    
    init(dependsOn: [TargetIdentity : Set<TargetIdentity>]) {
        self.dependsOn = dependsOn
    }
    
    func allTargets() -> [TargetIdentity] {
        return Array(dependsOn.keys)
    }
    
    func dependencies(for target: TargetIdentity) -> Set<TargetIdentity> {
        return dependsOn[target] ?? Set()
    }
    
    mutating func insert(_ target: TargetIdentity, dependOn: TargetIdentity) {
        var set = dependsOn[target] ?? Set<TargetIdentity>()
        
        set.insert(dependOn)
        dependsOn[target] = set
    }
    
    fileprivate func merge(with other: DependencyStructure) -> DependencyStructure {
        var map = self.dependsOn
        
        other.dependsOn.keys.forEach { key in
            let set = map[key] ?? Set<TargetIdentity>()
            
            map[key] = set.union(other.dependsOn[key]!)
        }
        
        return DependencyStructure(dependsOn: map)
    }
}
