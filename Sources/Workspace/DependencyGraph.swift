//
//  Created by Mike Gerasymenko <mike@gera.cx>
//

import Foundation

public extension Dictionary where Key == TargetIdentity, Value == Set<TargetIdentity> {
    
    func invert() -> [TargetIdentity: Set<TargetIdentity>] {
        var result: [TargetIdentity: Set<TargetIdentity>] = [:]
        self.forEach { (target, dependsOn) in
            dependsOn.forEach { dependency in
                result.insert(dependency, dependOn: target)
            }
        }
        return result
    }
    
    mutating func insert(_ target: TargetIdentity, dependOn: TargetIdentity) {
        var set = self[target] ?? Set<TargetIdentity>()
        set.insert(dependOn)
        self[target] = set
    }
}

public struct DependencyGraph {
    private var dependsOn: [TargetIdentity: Set<TargetIdentity>]
    private var affects: [TargetIdentity: Set<TargetIdentity>]
    
    public init(dependsOn: [TargetIdentity : Set<TargetIdentity>]) {
        self.dependsOn = dependsOn
        self.affects = dependsOn.invert()
    }
    
    public func allTargets() -> Set<TargetIdentity> {
        return Set(dependsOn.keys).union(Set(affects.keys))
    }
    
    public func dependencies(for target: TargetIdentity) -> Set<TargetIdentity> {
        return dependsOn[target] ?? Set()
    }
    
    public func affected(by target: TargetIdentity) -> Set<TargetIdentity> {
        return affects[target] ?? Set()
    }
    
    public func merging(with other: DependencyGraph) -> DependencyGraph {
        var map = self.dependsOn
        
        other.dependsOn.keys.forEach { key in
            let set = map[key] ?? Set<TargetIdentity>()
            
            map[key] = set.union(other.dependsOn[key]!)
        }
        
        return DependencyGraph(dependsOn: map)
    }
    
    public func findTarget(shortOrFullName: String) -> TargetIdentity? {
        let allTargets = self.allTargets()
        // Search full name first
        if let target = allTargets.first(where: { target in
            target.description == shortOrFullName
        }) {
            return target
        }
        // Search short name
        return allTargets.first(where: { target in
            target.simpleDescription == shortOrFullName
        })
    }
}
