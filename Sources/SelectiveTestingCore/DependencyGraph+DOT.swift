//
//  Created by Mike Gerasymenko <mike@gera.cx>
//

import Foundation
import Workspace
import PathKit

extension DependencyGraph {
    func dot() -> String {
        var dot = """
graph {
        rankdir=TB
"""
        let grouped = self.groupByPath()
        
        grouped.keys.sorted { lt, rt in
            
            if grouped[lt]?[0].isProject ?? false {
                return false
            }
            else {
                return !(grouped[rt]?[0].isProject ?? false)
            }
        }.forEach { path in
            let targets = grouped[path]!
            dot = dot + "\n{rank=same; \(targets.map(\.simpleDescription).joined(separator: ";"))}"
            targets.forEach { target in
                
                let dependencies = self.dependencies(for: target)
                
                dependencies.forEach { dep in
                    dot = dot + "\n\(target.simpleDescription) -> \(dep.simpleDescription)"
                }
            }
        }
        dot = dot + "\n}"
        return dot
    }
    
    func groupByPath() -> [Path: [TargetIdentity]] {
        var result = [Path: [TargetIdentity]]()
        
        self.allTargets().forEach { target in
            var targets = result[target.path] ?? [TargetIdentity]()
            targets.append(target)
            result[target.path] = targets
        }
        
        return result
    }
    
    public func renderToASCII() async throws -> String {
        return try await draw(dot: dot())
    }
}
