//
//  Created by Mike Gerasymenko <mike@gera.cx>
//

import Foundation
import PackagePlugin

@main
struct SelectiveTestingPlugin: CommandPlugin {
    private func run(_ executable: URL, arguments: [String] = []) throws {

        let process = Process()
        process.executableURL = executable
        process.arguments = arguments

        try process.run()
        process.waitUntilExit()

        let gracefulExit = process.terminationReason == .exit && process.terminationStatus == 0
        if !gracefulExit {
            throw "[ERROR] The plugin execution failed: \(process.terminationReason.rawValue) (\(process.terminationStatus))"
        }
    }

    func performCommand(context: PluginContext, arguments: [String]) async throws {
        FileManager.default.changeCurrentDirectoryPath(context.package.directoryURL.path)
        let tool = try context.tool(named: "xcode-selective-test")

        try run(tool.url, arguments: arguments)
    }
}

#if canImport(XcodeProjectPlugin)
    import XcodeProjectPlugin

    extension SelectiveTestingPlugin: XcodeCommandPlugin {
        func performCommand(context: XcodePluginContext, arguments: [String]) throws {
            FileManager.default.changeCurrentDirectoryPath(context.xcodeProject.directoryURL.path)

            let tool = try context.tool(named: "xcode-selective-test")

            var toolArguments = arguments

            if let indexOfTarget = toolArguments.firstIndex(of: "--target"),
                indexOfTarget != (toolArguments.count - 1) {
                toolArguments.remove(at: indexOfTarget + 1)
                toolArguments.remove(at: indexOfTarget)
            }
            
            if !toolArguments.contains(where: { $0 == "--test-plan" }) {
                let allFiles = context.xcodeProject.targets.reduce([]) { partialResult, target in
                    partialResult + target.inputFiles
                }
                
                let testPlans = allFiles.filter {
                    $0.url.pathExtension == "xctestplan"
                }

                if !testPlans.isEmpty {
                    if testPlans.count == 1 {
                        print("Using \(testPlans[0].url.path()) test plan")
                    } else {
                        print("Using \(testPlans.count) test plans")
                    }

                    for testPlan in testPlans {
                        toolArguments.append(contentsOf: ["--test-plan", testPlan.url.path()])
                    }
                }
            }

            try run(tool.url, arguments: toolArguments)
        }
    }
#endif

#if compiler(>=6)
extension String: @retroactive LocalizedError {
    public var errorDescription: String? { return self }
}
#else
extension String: LocalizedError {
    public var errorDescription: String? { return self }
}
#endif
