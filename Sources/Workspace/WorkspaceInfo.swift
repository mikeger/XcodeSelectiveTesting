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
    public let targetsForFiles: [Path: TargetIdentity]
    public let dependencyStructure: DependencyGraph
    
    public init(files: [TargetIdentity: Set<Path>], dependencyStructure: DependencyGraph) {
        self.files = files
        self.targetsForFiles = WorkspaceInfo.targets(for: files)
        self.dependencyStructure = dependencyStructure
    }
    
    public func merge(with other: WorkspaceInfo) -> WorkspaceInfo {
        let files = files.merging(with: other.files)
        let dependencyStructure = dependencyStructure.merge(with: other.dependencyStructure)
        
        return WorkspaceInfo(files: files, dependencyStructure: dependencyStructure)
    }
    
    static func targets(for files: [TargetIdentity: Set<Path>]) -> [Path: TargetIdentity] {
        var result: [Path: TargetIdentity] = [:]
        files.forEach { (target, files) in
            files.forEach { path in
                result[path] = target
            }
        }
        return result
    }
}
