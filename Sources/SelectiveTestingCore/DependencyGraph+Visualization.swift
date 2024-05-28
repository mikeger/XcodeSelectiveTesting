//
//  Created by Mike Gerasymenko <mike@gera.cx>
//

import Foundation
import PathKit
import Workspace

extension TargetIdentity {
    var dotDescription: String {
        return "\"\(description.replacingOccurrences(of: "-", with: "_"))\""
    }

    var mermaidDescription: String {
        return description.replacingOccurrences(of: " ", with: "_")
    }
}

extension DependencyGraph {
    func dot() -> String {
        var dot = """
        digraph {
                rankdir=TB
        """
        let grouped = groupByPath()

        for path in grouped.keys {
            let targets = grouped[path]!

            for target in targets {
                let deps = dependencies(for: target)
                guard !deps.isEmpty else {
                    continue
                }
                dot = dot + "\n\t\(target.dotDescription) -> { \(deps.map(\.dotDescription).joined(separator: " ")) }"
            }
        }
        dot = dot + "\n}"
        return dot
    }

    func mermaid(highlightTargets: Set<TargetIdentity>) -> String {
        var result = "graph TD\n"
        for target in allTargets() {
            let dependencies = dependencies(for: target)

            for dep in dependencies {
                result = result + "\n\(target.mermaidDescription) --> \(dep.mermaidDescription)"
            }
        }

        if !highlightTargets.isEmpty {
            result = result + "\nclassDef Red fill:#FF9999;\n class \(highlightTargets.map { $0.mermaidDescription }.joined(separator: ",")) Red;"
        }

        return result
    }

    func mermaidHTML(highlightTargets: Set<TargetIdentity>) -> String {
        let html = """
        <html>
        <body>
        <script src="https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.min.js" />
        <script type="javascript">
            const defaultConfig = {
                startOnLoad: true,
                securityLevel: 'loose',
                flowchart: {
                    useMaxWidth: 0,
                },
                gantt: {
                    useMaxWidth: 0,
                },
            }
            mermaid.initialize(defaultConfig)
        </script>
        <pre class="mermaid">{GRAPH}</pre>
        </body>
        """
        return html.replacingOccurrences(of: "{GRAPH}", with: mermaid(highlightTargets: highlightTargets))
    }

    func mermaidInURL(highlightTargets: Set<TargetIdentity>) -> String {
        return "data:text/html;base64,\(Data(mermaidHTML(highlightTargets: highlightTargets).utf8).base64EncodedString())"
    }

    func groupByPath() -> [Path: [TargetIdentity]] {
        var result = [Path: [TargetIdentity]]()

        for target in allTargets() {
            var targets = result[target.path] ?? [TargetIdentity]()
            targets.append(target)
            result[target.path] = targets
        }

        return result
    }
}
