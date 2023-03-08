//
//  Created by Mike Gerasymenko <mike@gera.cx>
//

import Foundation

public struct DependencyGraph {
    private var dependsOn: [TargetIdentity: Set<TargetIdentity>]
    
    public init(dependsOn: [TargetIdentity : Set<TargetIdentity>]) {
        self.dependsOn = dependsOn
    }
    
    public func allTargets() -> [TargetIdentity] {
        return Array(dependsOn.keys)
    }
    
    public func dependencies(for target: TargetIdentity) -> Set<TargetIdentity> {
        return dependsOn[target] ?? Set()
    }
    
    public mutating func insert(_ target: TargetIdentity, dependOn: TargetIdentity) {
        var set = dependsOn[target] ?? Set<TargetIdentity>()
        
        set.insert(dependOn)
        dependsOn[target] = set
    }
    
    public func merge(with other: DependencyGraph) -> DependencyGraph {
        var map = self.dependsOn
        
        other.dependsOn.keys.forEach { key in
            let set = map[key] ?? Set<TargetIdentity>()
            
            map[key] = set.union(other.dependsOn[key]!)
        }
        
        return DependencyGraph(dependsOn: map)
    }
}
