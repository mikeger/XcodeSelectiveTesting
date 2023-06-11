//
//  Created by Mike Gerasymenko <mike@gera.cx>
//

import SelectiveTestingCore
import ArgumentParser
import Logger

@main
struct SelectiveTesting: AsyncParsableCommand {
    static let configuration = CommandConfiguration(abstract: "Configure test plan to run only tests relevant for the changeset")

    @Argument(help: "Project or workspace path", completion: .file(extensions: ["xcworkspace", "xcodeproj"]))
    var projectOrWorkspacePath: String?
    
    @Option(name: .long, help: "Name of the base branch")
    var baseBranch: String?
    
    @Option(name: .long, help: "Test plan to modify")
    var testPlan: String?
    
    @Flag(name: .long, help: "Output in JSON format")
    var printJSON: Bool = false
    
    @Flag(help: "Render dependency graph in the browser")
    var renderDependencyGraph: Bool = false
    
    @Flag(help: "Produce verbose output")
    var verbose: Bool = false
    
    mutating func run() async throws {
        let tool = try SelectiveTestingTool(baseBranch: baseBranch,
                                            projectOrWorkspacePath: projectOrWorkspacePath,
                                            testPlan: testPlan,
                                            printJSON: printJSON,
                                            renderDependencyGraph: renderDependencyGraph,
                                            verbose: verbose)

        do {
            let _ = try await tool.run()
        } catch {
            Logger.error("\(error)")
        }
    }
}
