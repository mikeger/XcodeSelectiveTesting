import Foundation
import PathKit

public final class TestChangedTool {
    private let baseBranch: String
    private let projectWorkspacePath: Path
    private let renderDependencyGraph: Bool

    public init(baseBranch: String, projectWorkspacePath: String, renderDependencyGraph: Bool) {
        self.baseBranch = baseBranch
        self.projectWorkspacePath = Path(projectWorkspacePath)
        self.renderDependencyGraph = renderDependencyGraph
    }

    public func run() async throws {
        print("Running...")
        
        let changeset = try Changeset.gitChangeset(at: projectWorkspacePath.parent(), baseBranch: baseBranch)
        
        print("Changed files: \(changeset.changedPaths)")
        
        let workspaceInfo: WorkspaceInfo
        
        if projectWorkspacePath.extension == "xcworkspace" {
            workspaceInfo = try WorkspaceInfo.parseWorkspace(at: projectWorkspacePath)
        }
        else {
            workspaceInfo = try WorkspaceInfo.parseProject(at: projectWorkspacePath)
        }
        
        if renderDependencyGraph {
            print(try await workspaceInfo.dependencyStructure.renderToASCII())
        }
        
        workspaceInfo.files.keys.forEach { key in
            print("\(key): ")
            workspaceInfo.files[key]?.forEach { filePath in
                print("\t\(filePath)")
            }
        }
    }
}
