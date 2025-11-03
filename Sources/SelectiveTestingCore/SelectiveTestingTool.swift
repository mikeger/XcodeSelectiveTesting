//
//  Created by Mike Gerasymenko <mike@gera.cx>
//

import DependencyCalculator
import Foundation
import Git
import PathKit
import Logging
import SelectiveTestShell
import TestConfigurator
import Workspace

let logger = Logger(label: "cx.gera.XcodeSelectiveTesting")

public final class SelectiveTestingTool {
    private let baseBranch: String?
    private let basePath: Path
    private let printJSON: Bool
    private let changedFiles: [String]
    private let renderDependencyGraph: Bool
    private let turbo: Bool
    private let dryRun: Bool
    private let dot: Bool
    private let verbose: Bool
    private let testPlans: [String]
    private let config: Config?

    public init(baseBranch: String?,
                basePath: String?,
                testPlans: [String],
                changedFiles: [String],
                printJSON: Bool = false,
                renderDependencyGraph: Bool = false,
                dot: Bool = false,
                turbo: Bool = false,
                dryRun: Bool = false,
                verbose: Bool = false) throws
    {
        var configCandidates: [Path] = []
        if let suppliedBasePath = basePath.map({ Path($0) }) {
            let baseDirectory: Path
            if let ext = suppliedBasePath.extension,
               ext == "xcworkspace" || ext == "xcodeproj" {
                baseDirectory = suppliedBasePath.parent()
            } else if suppliedBasePath.isDirectory {
                baseDirectory = suppliedBasePath
            } else {
                baseDirectory = suppliedBasePath.parent()
            }
            configCandidates.append(baseDirectory + Config.defaultConfigName)
        }
        configCandidates.append(Path.current + Config.defaultConfigName)

        if let configPath = configCandidates.first(where: { $0.exists }),
           let configData = try? configPath.read(),
           let loadedConfig = try Config.load(from: configData) {
            self.config = loadedConfig
            if verbose {
                logger.info("Loaded config from \(configPath)")
            }
        } else {
            config = nil
        }

        let finalBasePath = Path(basePath ??
            config?.basePath ??
            Path().glob("*.xcworkspace").first?.string ??
            Path().glob("*.xcodeproj").first?.string ?? ".")

        self.baseBranch = baseBranch
        self.basePath = finalBasePath
        self.changedFiles = changedFiles
        self.printJSON = printJSON
        self.renderDependencyGraph = renderDependencyGraph
        self.turbo = turbo
        self.dot = dot
        self.dryRun = dryRun
        self.verbose = verbose

        // Merge CLI test plans with config test plans
        var allTestPlans: [String] = config?.allTestPlans ?? []
        allTestPlans.append(contentsOf: testPlans)
        self.testPlans = allTestPlans
    }

    public func run() async throws -> Set<TargetIdentity> {
        let workingDirectory: Path
        if let ext = basePath.extension,
           ext == "xcworkspace" || ext == "xcodeproj" {
            workingDirectory = basePath.parent()
        } else if basePath.isDirectory {
            workingDirectory = basePath
        } else {
            workingDirectory = basePath.parent()
        }
        // 1. Identify changed files
        let changeset: Set<Path>

        if changedFiles.isEmpty {
            logger.info("Finding changeset for repository at \(basePath)")
            if let baseBranch {
                changeset = try Git(path: basePath).changeset(baseBranch: baseBranch, verbose: verbose)
            } else {
                changeset = try Git(path: basePath).localChangeset()
            }
        }
        else {
            changeset = Set(changedFiles.map { Path($0).absolute() })
        }

        if verbose { logger.info("Changed files: \(changeset)") }

        // 2. Parse workspace: find which files belong to which targets and target dependencies
        let workspaceInfo = try WorkspaceInfo.parseWorkspace(at: basePath.absolute(),
                                                             config: config?.extra,
                                                             exclude: config?.exclude ?? [])

        // 3. Find affected targets
        let affectedTargets = workspaceInfo.affectedTargets(changedFiles: changeset,
                                                            incldueIndirectlyAffected: !turbo)

        if renderDependencyGraph {
            try Shell.exec("open -a Safari \"\(workspaceInfo.dependencyStructure.mermaidInURL(highlightTargets: affectedTargets))\"")
        }

        if printJSON {
            try printJSON(affectedTargets: affectedTargets)
        } else if dot {
            print(workspaceInfo.dependencyStructure.dot())
        }

        if verbose {
            workspaceInfo.dependencyStructure
                .allTargets()
                .sorted(by: { $0.description < $1.description }).forEach { target in
                    switch target.type {
                    case .package:
                        logger.info("Package target at \(target.path): \(target.name) depends on:")

                    case .project:
                        logger.info("Project target at \(target.path): \(target.name) depends on:")
                    }

                    workspaceInfo.dependencyStructure
                        .dependencies(for: target)
                        .sorted(by: { $0.description < $1.description }).forEach { dependency in
                            logger.info("    ﹂\(dependency)")
                        }
                }

            logger.info("Files for targets:")
            for key in workspaceInfo.files.keys.sorted(by: { $0.description < $1.description }) {
                logger.info("\(key.description): ")
                workspaceInfo.files[key]?.forEach { filePath in
                    logger.info("\t\(filePath)")
                }
            }

            logger.info("Folders for targets:")
            for (key, folder) in workspaceInfo.folders.sorted(by: { $0.key < $1.key }) {
                logger.info("\t\(folder): \(key)")
            }
        }

        if !dryRun {
            // 4. Configure workspace to test given targets
            let plansToUpdate = testPlans.isEmpty ?
            workspaceInfo.candidateTestPlans :
            testPlans.map { plan in
                let planPath = Path(plan)
                let resolved = planPath.isAbsolute ? planPath : workingDirectory + planPath
                return resolved.absolute().string
            }

            if !plansToUpdate.isEmpty {
                for testPlan in plansToUpdate {
                    try enableTests(at: Path(testPlan),
                                    targetsToTest: affectedTargets)
                }
            } else if !printJSON {
                if affectedTargets.isEmpty {
                    if verbose { logger.info("No targets affected") }
                } else {
                    if verbose { logger.info("Targets to test:") }

                    for target in affectedTargets {
                        logger.info(Logger.Message(stringLiteral: target.description))
                    }
                }
            }
        } else if !printJSON {
            if affectedTargets.isEmpty {
                if verbose { logger.info("No targets affected") }
            } else {
                if verbose { logger.info("Targets to test:") }

                for target in affectedTargets {
                    logger.info(Logger.Message(stringLiteral: target.description))
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
