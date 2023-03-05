import TestChangedCore
import ArgumentParser

@main
struct TestChanged: AsyncParsableCommand {
    
    @Argument(help: "Name of the base branch")
    var baseBranch: String = ""
    
    @Argument(help: "Project or workspace path", completion: .file(extensions: ["xcworkspace", "xcodeproj"]))
    var projectWorkspacePath: String = ""
    
    mutating func run() async throws {
        let tool = TestChangedTool(baseBranch: baseBranch, projectWorkspacePath: projectWorkspacePath)

        do {
            try await tool.run()
        } catch {
            print("Error: \(error)")
        }
    }
}
