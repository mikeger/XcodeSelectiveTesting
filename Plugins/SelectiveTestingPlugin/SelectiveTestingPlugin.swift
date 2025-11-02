//
//  Created by Mike Gerasymenko <mike@gera.cx>
//

import Foundation
import PackagePlugin

@main
struct SelectiveTestingPlugin: CommandPlugin {
    private func run(_ executable: String, arguments: [String] = []) throws {
        let executableURL = URL(fileURLWithPath: executable)

        let process = Process()
        process.executableURL = executableURL
        process.arguments = arguments

        try process.run()
        process.waitUntilExit()

        let gracefulExit = process.terminationReason == .exit && process.terminationStatus == 0
        if !gracefulExit {
            throw "[ERROR] The plugin execution failed: \(process.terminationReason.rawValue) (\(process.terminationStatus))"
        }
    }

    func performCommand(context: PluginContext, arguments: [String]) async throws {
        FileManager().changeCurrentDirectoryPath(context.package.directory.string)
        let tool = try context.tool(named: "xcode-selective-test")

        try run(tool.path.string, arguments: arguments)
    }
}

#if canImport(XcodeProjectPlugin)
    import XcodeProjectPlugin

    extension SelectiveTestingPlugin: XcodeCommandPlugin {
        func performCommand(context: XcodePluginContext, arguments: [String]) throws {
            FileManager().changeCurrentDirectoryPath(context.xcodeProject.directory.string)

            let tool = try context.tool(named: "xcode-selective-test")

            var toolArguments = arguments

            if let indexOfTarget = toolArguments.firstIndex(of: "--target"),
                indexOfTarget != (toolArguments.count - 1) {
                toolArguments.remove(at: indexOfTarget + 1)
                toolArguments.remove(at: indexOfTarget)
            }
            
            if !toolArguments.contains(where: { $0 == "--test-plan" }) {
                let testPlans = context.xcodeProject.filePaths.filter {
                    $0.extension == "xctestplan"
                }

                if !testPlans.isEmpty {
                    if testPlans.count == 1 {
                        print("Using \(testPlans[0].string) test plan")
                    } else {
                        print("Using \(testPlans.count) test plans")
                    }

                    for testPlan in testPlans {
                        toolArguments.append(contentsOf: ["--test-plan", testPlan.string])
                    }
                }
            }

            try run(tool.path.string, arguments: toolArguments)
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
