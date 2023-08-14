//
//  Created by Mike Gerasymenko <mike@gera.cx>
//

import Foundation
import PackagePlugin

@main
struct SelectiveTestingPlugin: CommandPlugin {
    private func run(_ executable: String, args: [String] = []) throws {
        let executableURL = URL(fileURLWithPath: executable)
        
        let process = Process()
        process.executableURL = executableURL
        process.arguments = args
        
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
        
        try run(tool.path.string)
    }
}

#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

extension SelectiveTestingPlugin: XcodeCommandPlugin {
    func performCommand(context: XcodePluginContext, arguments: [String]) throws {
        FileManager().changeCurrentDirectoryPath(context.xcodeProject.directory.string)
        
        let testPlan = context.xcodeProject.filePaths.first {
            $0.extension == "xctestplan"
        }
        
        let tool = try context.tool(named: "xcode-selective-test")
        
        if let testPlan {
            print("Using \(testPlan.string) test plan")
            try run(tool.path.string, args: ["--test-plan", testPlan.string])
        }
        else {
            try run(tool.path.string)
        }
    }
}
#endif

extension String: LocalizedError {
    public var errorDescription: String? { return self }
}
