//
//  Created by Mike Gerasymenko <mike@gera.cx>
//

import Foundation
import PathKit
import Git
import Workspace
import Logger
import DependencyCalculator
import TestConfigurator

public final class SelectiveTestingTool {
    private let baseBranch: String?
    private let projectWorkspacePath: Path
    private let renderDependencyGraph: Bool
    private let testPlan: String?

    public init(baseBranch: String?, projectWorkspacePath: String, testPlan: String?, renderDependencyGraph: Bool) {
        self.baseBranch = baseBranch
        self.projectWorkspacePath = Path(projectWorkspacePath)
        self.renderDependencyGraph = renderDependencyGraph
        self.testPlan = testPlan
    }

    public func run() async throws -> Set<TargetIdentity> {
        Logger.message("Running...")
        
        // 1. Identify changed files
        let changeset: Set<Path>
        
        if let baseBranch {
            changeset = try Changeset.gitChangeset(at: projectWorkspacePath, baseBranch: baseBranch)
        }
        else {
            changeset = try Changeset.gitLocalChangeset(at: projectWorkspacePath)
        }
        
        Logger.message("Changed files: \(changeset)")
        
        // 2. Parse workspace: find which files belong to which targets and target dependencies
        let workspaceInfo = try WorkspaceInfo.parseWorkspace(at: projectWorkspacePath.absolute())
        
        if renderDependencyGraph {
            Logger.message(try await workspaceInfo.dependencyStructure.renderToASCII())
            
            workspaceInfo.files.keys.forEach { key in
                print("\(key.simpleDescription): ")
                workspaceInfo.files[key]?.forEach { filePath in
                    print("\t\(filePath)")
                }
            }
        }
        
        // 3. Find affected targets
        let affectedTargets = workspaceInfo.affectedTargets(changedFiles: changeset)
        
        if let testPlan {
            // 4. Configure workspace to test given targets
            try enableTests(at: Path(testPlan),
                            targetsToTest: affectedTargets)
        }
        else {
            print("========================== Targets to test: ==========================")
            
            affectedTargets.forEach { target in
                switch target {
                case .target(let path, let name):
                    print("Target at \(path): \(name)")
                case .swiftPackage(let path, let name):
                    print("Package at \(path): \(name)")
                }
            }
        }
        
        return affectedTargets
    }
}
