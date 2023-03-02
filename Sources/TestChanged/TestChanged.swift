import TestChangedCore
import ArgumentParser

@main
struct TestChanged: ParsableCommand {
    
    @Argument(help: "Path for the repository")
    var path: String = ""
    
    @Argument(help: "Name of the base branch")
    var baseBranch: String = ""
    
    @Argument(help: "Project or workspace path")
    var projectWorkspacePath: String = ""
    
    public func main() async {
        let tool = TestChangedTool(path: path, baseBranch: baseBranch, projectWorkspacePath: projectWorkspacePath)

        do {
            try await tool.run()
        } catch {
            print("Error: \(error)")
        }
    }
}
