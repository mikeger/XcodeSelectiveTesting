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

            if !toolArguments.contains(where: { $0 == "--test-plan" }),
               let testPlan = context.xcodeProject.filePaths.first(where: {
                   $0.extension == "xctestplan"
               })
            {
                print("Using \(testPlan.string) test plan")
                toolArguments.append(contentsOf: ["--test-plan", testPlan.string])
            }

            try run(tool.path.string, arguments: toolArguments)
        }
    }
#endif

extension String: @retroactive LocalizedError {
    public var errorDescription: String? { return self }
}
