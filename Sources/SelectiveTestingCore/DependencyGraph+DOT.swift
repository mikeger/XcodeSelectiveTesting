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
        
        grouped.keys.forEach { path in
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
    
    func mermaid(highlightTargets: Set<TargetIdentity>) -> String {
        var result = "graph TD\n"
        self.allTargets().forEach { target in
                
            let dependencies = self.dependencies(for: target)
            
            dependencies.forEach { dep in
                result = result + "\n\(target.simpleDescriptionEscaped) --> \(dep.simpleDescriptionEscaped)"
            }
        }
        
        if !highlightTargets.isEmpty {
            result = result + "\nclassDef Red fill:#FF9999;\n class \(highlightTargets.map { $0.simpleDescription }.joined(separator: ",")) Red;"
        }

        return result
    }
    
    func mermaidHTML(highlightTargets: Set<TargetIdentity>) -> String {
        let html = """
<html><body><script src="https://cdn.jsdelivr.net/npm/mermaid@10.2.3/dist/mermaid.min.js" /><script type="javascript">mermaid.initialize()</script><pre class="mermaid">{GRAPH}</pre></body></script>
"""
        return html.replacingOccurrences(of: "{GRAPH}", with: mermaid(highlightTargets: highlightTargets))
    }
    
    func mermaidInURL(highlightTargets: Set<TargetIdentity>) -> String {
        return "data:text/html;base64,\(Data(mermaidHTML(highlightTargets: highlightTargets).utf8).base64EncodedString())"
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
#if os(macOS)
    public func renderToASCII() async throws -> String {
        return try await draw(dot: dot())
    }
#endif
}
