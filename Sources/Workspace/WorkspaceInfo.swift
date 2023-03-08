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
    public let dependencyStructure: DependencyGraph
    
    public init(files: [TargetIdentity : Set<Path>], dependencyStructure: DependencyGraph) {
        self.files = files
        self.dependencyStructure = dependencyStructure
    }
    
    public func merge(with other: WorkspaceInfo) -> WorkspaceInfo {
        let dependencyStructure = dependencyStructure.merge(with: other.dependencyStructure)
        
        return WorkspaceInfo(files: files.merging(with: other.files), dependencyStructure: dependencyStructure)
    }
}
