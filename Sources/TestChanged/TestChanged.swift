import TestChangedCore
import ArgumentParser

@main
struct TestChanged: AsyncParsableCommand {
    
    @Argument(help: "Name of the base branch")
    var baseBranch: String = ""
    
    @Argument(help: "Project or workspace path", completion: .file(extensions: ["xcworkspace", "xcodeproj"]))
    var projectWorkspacePath: String = ""
    
    @Flag(help: "Use dot-to-ascii.ggerganov.com to render dependency graph in the terminal")
    var renderDependencyGraph: Bool = false
    
    mutating func run() async throws {
        let tool = TestChangedTool(baseBranch: baseBranch, projectWorkspacePath: projectWorkspacePath, renderDependencyGraph: renderDependencyGraph)

        do {
            try await tool.run()
        } catch {
            print("Error: \(error)")
        }
    }
}
