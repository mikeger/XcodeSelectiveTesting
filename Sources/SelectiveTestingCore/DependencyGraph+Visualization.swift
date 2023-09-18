//
//  Created by Mike Gerasymenko <mike@gera.cx>
//

import Foundation
import Workspace
import PathKit

extension TargetIdentity {
    var dotDescription: String {
        return "\"\(self.description.replacingOccurrences(of: "-", with: "_"))\""
    }
}

extension DependencyGraph {
    func dot() -> String {
        var dot = """
digraph {
        rankdir=TB
"""
        let grouped = groupByPath()

        grouped.keys.forEach { path in
            let targets = grouped[path]!
            
            targets.forEach { target in
                let deps = dependencies(for: target)
                guard !deps.isEmpty else {
                    return
                }
                dot = dot + "\n\t\(target.dotDescription) -> { \(deps.map(\.dotDescription).joined(separator: " ")) }"
            }
        }
        dot = dot + "\n}"
        return dot
    }
    
    func mermaid(highlightTargets: Set<TargetIdentity>) -> String {
        var result = "graph TD\n"
        allTargets().forEach { target in
                
            let dependencies = dependencies(for: target)
            
            dependencies.forEach { dep in
                result = result + "\n\(target.description) --> \(dep.description)"
            }
        }
        
        if !highlightTargets.isEmpty {
            result = result + "\nclassDef Red fill:#FF9999;\n class \(highlightTargets.map { $0.description }.joined(separator: ",")) Red;"
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
        
        allTargets().forEach { target in
            var targets = result[target.path] ?? [TargetIdentity]()
            targets.append(target)
            result[target.path] = targets
        }
        
        return result
    }
}
