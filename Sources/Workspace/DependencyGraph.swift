//
//  Created by Mike Gerasymenko <mike@gera.cx>
//

import Foundation

public extension Dictionary where Key == TargetIdentity, Value == Set<TargetIdentity> {
    func invert() -> [TargetIdentity: Set<TargetIdentity>] {
        var result: [TargetIdentity: Set<TargetIdentity>] = [:]
        forEach { target, dependsOn in
            for dependency in dependsOn {
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

    public init(dependsOn: [TargetIdentity: Set<TargetIdentity>]) {
        self.dependsOn = dependsOn
        affects = dependsOn.invert()
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
        var map = dependsOn

        for key in other.dependsOn.keys {
            let set = map[key] ?? Set<TargetIdentity>()

            map[key] = set.union(other.dependsOn[key]!)
        }

        return DependencyGraph(dependsOn: map)
    }

    public func reachableTargets(startingFrom roots: Set<TargetIdentity>) -> Set<TargetIdentity> {
        guard !roots.isEmpty else { return [] }

        var visited = Set<TargetIdentity>()
        var stack = Array(roots)

        while let current = stack.popLast() {
            if visited.contains(current) {
                continue
            }
            visited.insert(current)

            let dependencies = dependsOn[current] ?? Set<TargetIdentity>()
            for dependency in dependencies where !visited.contains(dependency) {
                stack.append(dependency)
            }
        }

        return visited
    }

    public func filteringTargets(_ allowed: Set<TargetIdentity>) -> DependencyGraph {
        guard !allowed.isEmpty else { return DependencyGraph(dependsOn: [:]) }

        var filtered: [TargetIdentity: Set<TargetIdentity>] = [:]

        for target in allowed {
            let dependencies = (dependsOn[target] ?? Set<TargetIdentity>()).intersection(allowed)
            filtered[target] = dependencies
        }

        return DependencyGraph(dependsOn: filtered)
    }
}
