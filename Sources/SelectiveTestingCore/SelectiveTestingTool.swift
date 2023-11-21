//
//  Created by Mike Gerasymenko <mike@gera.cx>
//

import Foundation
import PathKit
import Git
import Workspace
import SelectiveTestLogger
import SelectiveTestShell
import DependencyCalculator
import TestConfigurator

public final class SelectiveTestingTool {
    private let baseBranch: String?
    private let basePath: Path
    private let printJSON: Bool
    private let renderDependencyGraph: Bool
    private let dot: Bool
    private let verbose: Bool
    private let testPlan: String?
    private let config: Config?

    public init(baseBranch: String?,
                basePath: String?,
                testPlan: String?,
                printJSON: Bool = false,
                renderDependencyGraph: Bool = false,
                dot: Bool = false,
                verbose: Bool = false) throws {
        
        if let configData = try? (Path.current + Config.defaultConfigName).read(),
           let config = try Config.load(from: configData) {
            self.config = config
        }
        else {
            config = nil
        }
        
        let finalBasePath = basePath ??
                config?.basePath ??
                Path().glob("*.xcworkspace").first?.string ??
                Path().glob("*.xcodeproj").first?.string ?? "."
        
        self.baseBranch = baseBranch
        self.basePath = Path(finalBasePath)
        self.printJSON = printJSON
        self.renderDependencyGraph = renderDependencyGraph
        self.dot = dot
        self.verbose = verbose
        self.testPlan = testPlan ?? config?.testPlan
    }

    public func run() async throws -> Set<TargetIdentity> {
        
        // 1. Identify changed files
        let changeset: Set<Path>
        
        Logger.message("Finding changeset for repository at \(basePath)")
        if let baseBranch {
            changeset = try Git(path: basePath).changeset(baseBranch: baseBranch, verbose: verbose)
        }
        else {
            changeset = try Git(path: basePath).localChangeset()
        }
        
        if verbose { Logger.message("Changed files: \(changeset)") }
        
        // 2. Parse workspace: find which files belong to which targets and target dependencies
        let workspaceInfo = try WorkspaceInfo.parseWorkspace(at: basePath.absolute(),
                                                             config: config?.extra,
                                                             exclude: config?.exclude ?? [])
        
        // 3. Find affected targets
        let affectedTargets = workspaceInfo.affectedTargets(changedFiles: changeset)
        
        if renderDependencyGraph {
            try Shell.exec("open -a Safari \"\(workspaceInfo.dependencyStructure.mermaidInURL(highlightTargets: affectedTargets))\"")
        }
        
        if printJSON {
            try printJSON(affectedTargets: affectedTargets)
        }
        else if dot {
            print(workspaceInfo.dependencyStructure.dot())
        }
        
        if verbose {
            workspaceInfo.dependencyStructure
                .allTargets()
                .sorted(by: { $0.description < $1.description }).forEach { target in
                    switch target.type {
                    case .package:
                        Logger.message("Package target at \(target.path): \(target.name) depends on:")

                    case .project:
                        Logger.message("Project target at \(target.path): \(target.name) depends on:")
                    }
                
                workspaceInfo.dependencyStructure
                    .dependencies(for: target)
                    .sorted(by: { $0.description < $1.description }).forEach { dependency in
                    Logger.message("    ﹂\(dependency)")
                }
            }
            
            Logger.message("Files for targets:")
            workspaceInfo.files.keys.sorted(by: { $0.description < $1.description }).forEach { key in
                Logger.message("\(key.description): ")
                workspaceInfo.files[key]?.forEach { filePath in
                    Logger.message("\t\(filePath)")
                }
            }
            
            Logger.message("Folders for targets:")
            workspaceInfo.folders.sorted(by: { $0.key < $1.key }).forEach { key, folder in
                Logger.message("\t\(folder): \(key)")
            }
        }
        
        if let testPlan {
            // 4. Configure workspace to test given targets
            try enableTests(at: Path(testPlan),
                            targetsToTest: affectedTargets)
        }
        else if let testPlan = workspaceInfo.candidateTestPlan {
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
                case packageTarget
                case target
            }
            let name: String
            let type: TargetType
            let path: String
            let testTarget: Bool
        }
        
        let array = Array(affectedTargets.map { target in
            switch target.type {
            case .package:
                return TargetIdentitySerialization(name: target.name, type: .packageTarget, path: target.path.string, testTarget: target.isTestTarget)
            case .project:
                return TargetIdentitySerialization(name: target.name, type: .target, path: target.path.string, testTarget: target.isTestTarget)
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
