//
//  Created by Mike Gerasymenko <mike@gera.cx>
//

import Foundation
import PathKit
import Git
import Workspace
import Logger
import Shell
import DependencyCalculator
import TestConfigurator

public final class SelectiveTestingTool {
    private let baseBranch: String?
    private let projectOrWorkspacePath: Path
    private let printJSON: Bool
    private let renderDependencyGraph: Bool
    private let verbose: Bool
    private let testPlan: String?
    private let config: Config?

    public init(baseBranch: String?,
                projectOrWorkspacePath: String?,
                testPlan: String?,
                printJSON: Bool = false,
                renderDependencyGraph: Bool = false,
                verbose: Bool = false) throws {
        
        if let configData = try? (Path.current + Config.defaultConfigName).read(),
           let config = try Config.load(from: configData) {
            self.config = config
        }
        else {
            config = nil
        }
        
        guard let finalProjectOrWorkspacePath = projectOrWorkspacePath ?? config?.projectOrWorkspace else {
            throw "No project or workspace path provided. Configure with command line or via \(Config.defaultConfigName)"
        }
        
        self.baseBranch = baseBranch
        self.projectOrWorkspacePath = Path(finalProjectOrWorkspacePath)
        self.printJSON = printJSON
        self.renderDependencyGraph = renderDependencyGraph
        self.verbose = verbose
        self.testPlan = testPlan ?? config?.testPlan
    }

    public func run() async throws -> Set<TargetIdentity> {
        
        // 1. Identify changed files
        let changeset: Set<Path>
        
        if verbose { Logger.message("Finding changeset for repository at \(projectOrWorkspacePath)") }
        if let baseBranch {
            changeset = try Git(path: projectOrWorkspacePath).changeset(baseBranch: baseBranch, verbose: verbose)
        }
        else {
            changeset = try Git(path: projectOrWorkspacePath).localChangeset()
        }
        
        if verbose { Logger.message("Changed files: \(changeset)") }
        
        // 2. Parse workspace: find which files belong to which targets and target dependencies
        let workspaceInfo = try WorkspaceInfo.parseWorkspace(at: projectOrWorkspacePath.absolute(),
                                                             config: config?.extra)
        
        // 3. Find affected targets
        let affectedTargets = workspaceInfo.affectedTargets(changedFiles: changeset)
        
        if renderDependencyGraph {
            //Logger.message(try await workspaceInfo.dependencyStructure.renderToASCII())
            
            try Shell.exec("open -a Safari \"\(workspaceInfo.dependencyStructure.mermaidInURL(highlightTargets: affectedTargets))\"")
            
            workspaceInfo.files.keys.forEach { key in
                Logger.message("\(key.simpleDescription): ")
                workspaceInfo.files[key]?.forEach { filePath in
                    Logger.message("\t\(filePath)")
                }
            }
        }
        
        if printJSON {
            try printJSON(affectedTargets: affectedTargets)
        }
        
        if let testPlan {
            // 4. Configure workspace to test given targets
            try enableTests(at: Path(testPlan),
                            targetsToTest: affectedTargets)
        }
        else if !printJSON {
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
    
    private func printJSON(affectedTargets: Set<TargetIdentity>) throws {
        struct TargetIdentitySerialization: Encodable {
            enum TargetType: String, Encodable {
                case swiftPackage
                case target
            }
            let name: String
            let type: TargetType
            let path: String
        }
        
        let array = Array(affectedTargets.map { target in
            switch target {
            case .swiftPackage(let path, let name):
                return TargetIdentitySerialization(name: name, type: .swiftPackage, path: path.string)
            case .target(let path, let name):
                return TargetIdentitySerialization(name: name, type: .target, path: path.string)
            }
        })
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let jsonData = try encoder.encode(array)
        
        guard let string = String(data: jsonData, encoding: .utf8) else {
           return
        }
        
        print(string)
    }
}
