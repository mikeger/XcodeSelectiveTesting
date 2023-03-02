import Foundation
import PathKit

public final class TestChangedTool {
    private let path: Path
    private let baseBranch: String
    private let projectWorkspacePath: Path

    public init(path: String, baseBranch: String, projectWorkspacePath: String) {
        self.path = Path(path)
        self.baseBranch = baseBranch
        self.projectWorkspacePath = Path(projectWorkspacePath)
    }

    public func run() async throws {
        
        let changeset = try Changeset.gitChangeset(at: path, baseBranch: baseBranch)
        
        let dependencyStructure: DependencyStructure
        
        if projectWorkspacePath.extension == "xcworkspace" {
            dependencyStructure = try DependencyStructure.parseWorkspace(at: projectWorkspacePath)
        }
        else {
            dependencyStructure = try DependencyStructure.parseProject(at: projectWorkspacePath)
        }
        
        dependencyStructure.allTargets().forEach { target in
            print("Target: \(target)")
            
            print("Dependencies: \(dependencyStructure.dependencies(for: target))")
        }
    }
}
