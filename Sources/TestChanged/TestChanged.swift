import TestChangedCore
import ArgumentParser

@main
struct TestChanged: ParsableCommand {
    
    @Argument(help: "Name of the base branch")
    var baseBranch: String = ""
    
    @Argument(help: "Project or workspace path", completion: .file(extensions: ["xcworkspace", "xcodeproj"]))
    var projectWorkspacePath: String = ""
    
    mutating func run() throws {
        let tool = TestChangedTool(baseBranch: baseBranch, projectWorkspacePath: projectWorkspacePath)

        do {
            try tool.run()
        } catch {
            print("Error: \(error)")
        }
    }
}
