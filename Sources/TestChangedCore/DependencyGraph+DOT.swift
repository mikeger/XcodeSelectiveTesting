//
//  Created by Mike Gerasymenko <mike@gera.cx>
//

import Foundation
import Workspace

extension DependencyGraph {
    func dot() -> String {
        var dot = """
graph {
        rankdir=LR
"""
        self.allTargets().forEach { target in
            
            let dependencies = self.dependencies(for: target)
            
            dependencies.forEach { dep in
                dot = dot + "\n\(target.simpleDescription) -> \(dep.simpleDescription)"
            }
        }
        dot = dot + "\n}"
        return dot
    }
    
    func renderToASCII() async throws -> String {
        return try await draw(dot: dot())
    }
}
