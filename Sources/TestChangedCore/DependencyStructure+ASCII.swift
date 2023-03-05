import Foundation

extension DependencyStructure {
    func renderToASCII() async throws -> String {
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
        
        return try await draw(dot: dot)
    }
}
