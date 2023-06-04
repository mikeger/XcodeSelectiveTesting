//
//  Created by Mike Gerasymenko <mike@gera.cx>
//

import Foundation
import PathKit
import XcodeProj
import Logger

public extension Dictionary where Key == TargetIdentity, Value == Set<Path> {
    func merging(with other: Self) -> Self {
        self.merging(other, uniquingKeysWith: { first, second in
            first.union(second)
        })
    }
}

public struct WorkspaceInfo {
    public let files: [TargetIdentity: Set<Path>]
    public let targetsForFiles: [Path: Set<TargetIdentity>]
    public let dependencyStructure: DependencyGraph
    
    public init(files: [TargetIdentity: Set<Path>], dependencyStructure: DependencyGraph) {
        self.files = files
        self.targetsForFiles = WorkspaceInfo.targets(for: files)
        self.dependencyStructure = dependencyStructure
    }
    
    public func merging(with other: WorkspaceInfo) -> WorkspaceInfo {
        let files = files.merging(with: other.files)
        let dependencyStructure = dependencyStructure.merging(with: other.dependencyStructure)
        
        return WorkspaceInfo(files: files, dependencyStructure: dependencyStructure)
    }
    
    static func targets(for targetsToFiles: [TargetIdentity: Set<Path>]) -> [Path: Set<TargetIdentity>] {
        var result: [Path: Set<TargetIdentity>] = [:]
        targetsToFiles.forEach { (target, files) in
            files.forEach { path in
                var existing = result[path] ?? Set()
                existing.insert(target)
                result[path] = existing
            }
        }
        return result
    }
}
