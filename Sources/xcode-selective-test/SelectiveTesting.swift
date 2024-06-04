//
//  Created by Mike Gerasymenko <mike@gera.cx>
//

import ArgumentParser
import SelectiveTestingCore
import SelectiveTestLogger

@main
struct SelectiveTesting: AsyncParsableCommand {
    static let configuration = CommandConfiguration(abstract: "Configure test plan to run only tests relevant for the changeset")

    @Argument(help: "Project, workspace or package path", completion: .file(extensions: ["xcworkspace", "xcodeproj"]))
    var basePath: String?

    @Option(name: .long, help: "Name of the base branch")
    var baseBranch: String?

    @Option(name: .long, help: "Test plan to modify")
    var testPlan: String?

    @Flag(name: .long, help: "Output in JSON format")
    var JSON: Bool = false

    @Flag(help: "Render dependency graph in the browser using Mermaid")
    var dependencyGraph: Bool = false

    @Flag(help: "Output dependency graph in Dot (Graphviz) format")
    var dot: Bool = false

    @Flag(help: "Turbo mode: run directly affected tests only")
    var turbo: Bool = false
    
    @Flag(help: "Produce verbose output")
    var verbose: Bool = false

    mutating func run() async throws {
        let tool = try SelectiveTestingTool(baseBranch: baseBranch,
                                            basePath: basePath,
                                            testPlan: testPlan,
                                            printJSON: JSON,
                                            renderDependencyGraph: dependencyGraph,
                                            dot: dot,
                                            turbo: turbo,
                                            verbose: verbose)
        let _ = try await tool.run()
    }
}
