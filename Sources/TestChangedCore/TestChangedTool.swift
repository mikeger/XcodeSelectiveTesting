import Foundation
import PathKit

public final class TestChangedTool {
    private let baseBranch: String
    private let projectWorkspacePath: Path

    public init(baseBranch: String, projectWorkspacePath: String) {
        self.baseBranch = baseBranch
        self.projectWorkspacePath = Path(projectWorkspacePath)
    }

    public func run() throws {
        print("Running...")
        
        let changeset = try Changeset.gitChangeset(at: projectWorkspacePath.parent(), baseBranch: baseBranch)
        
        print("Changed files: \(changeset.changedPaths)")
        
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
