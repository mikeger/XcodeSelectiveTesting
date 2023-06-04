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
    private let verbose: Bool
    private let testPlan: String?

    public init(baseBranch: String?,
                projectWorkspacePath: String,
                testPlan: String?,
                renderDependencyGraph: Bool = false,
                verbose: Bool = false) {
        self.baseBranch = baseBranch
        self.projectWorkspacePath = Path(projectWorkspacePath)
        self.renderDependencyGraph = renderDependencyGraph
        self.verbose = verbose
        self.testPlan = testPlan
    }

    public func run() async throws -> Set<TargetIdentity> {
        
        // 1. Identify changed files
        let changeset: Set<Path>
        
        if verbose { Logger.message("Finding changeset for repository at \(projectWorkspacePath)") }
        if let baseBranch {
            changeset = try Changeset.gitChangeset(at: projectWorkspacePath, baseBranch: baseBranch, verbose: verbose)
        }
        else {
            changeset = try Changeset.gitLocalChangeset(at: projectWorkspacePath)
        }
        
        if verbose { Logger.message("Changed files: \(changeset)") }
        
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
            if affectedTargets.isEmpty {
                if verbose { Logger.message("No targets affected") }
            }
            else {
                if verbose { Logger.message("Targets to test:") }
                
                affectedTargets.forEach { target in
                    Logger.message(target.description)
                }
            }
        }
        
        return affectedTargets
    }
}
