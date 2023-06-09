//
//  Created by Mike Gerasymenko <mike@gera.cx>
//

import SelectiveTestingCore
import ArgumentParser
import Logger

@main
struct SelectiveTesting: AsyncParsableCommand {
    
    @Argument(help: "Project or workspace path", completion: .file(extensions: ["xcworkspace", "xcodeproj"]))
    var projectWorkspacePath: String
    
    @Option(name: .long, help: "Name of the base branch")
    var baseBranch: String?
    
    @Option(name: .long, help: "Test plan to modify")
    var testPlan: String?
    
    @Flag(name: .long, help: "Output in JSON format")
    var printJSON: Bool = false
    
    @Flag(help: "Use dot-to-ascii.ggerganov.com to render dependency graph in the terminal")
    var renderDependencyGraph: Bool = false
    
    @Flag(help: "Produce verbose aoutput")
    var verbose: Bool = false
    
    mutating func run() async throws {
        let tool = SelectiveTestingTool(baseBranch: baseBranch,
                                        projectWorkspacePath: projectWorkspacePath,
                                        testPlan: testPlan,
                                        printJSON: printJSON,
                                        renderDependencyGraph: renderDependencyGraph,
                                        verbose: verbose)

        do {
            let _ = try await tool.run()
        } catch {
            Logger.error("Caught: \(error)")
        }
    }
}
