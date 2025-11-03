//
//  Created by Mike Gerasymenko <mike@gera.cx>
//

import Foundation
import PathKit
@testable import SelectiveTestingCore
import SelectiveTestShell
import Testing
import TestConfigurator
import Workspace

struct IntegrationTestTool {
    var projectPath: Path = ""

    private func runInProject(_ command: String) throws {
        try Shell.execOrFail("(cd \"\(projectPath.string)\" && \(command))")
    }

    init(subfolder: Bool = false) throws {
        let tmpPath = Path.temporary.absolute()
        let uniqueFolder = "ExampleProject-\(UUID().uuidString)"
        guard let exampleInBundle = Bundle.module.path(forResource: "ExampleProject", ofType: "") else {
            fatalError("Missing ExampleProject in TestBundle")
        }
        projectPath = tmpPath + uniqueFolder
        try? FileManager.default.removeItem(atPath: projectPath.string)
        if subfolder {
            let finalPath = (projectPath + "Subfolder").string
            try FileManager.default.createDirectory(atPath: projectPath.string, withIntermediateDirectories: true)
            try FileManager.default.copyItem(atPath: exampleInBundle, toPath: finalPath)
        }
        else {
            try FileManager.default.copyItem(atPath: exampleInBundle, toPath: projectPath.string)
        }
        try runInProject("git init")
        try runInProject("git config commit.gpgsign false")
        try runInProject("git checkout -b main")
        try runInProject("git add .")
        try runInProject("git commit -m \"Base\"")
        try runInProject("git checkout -b feature")
    }

    func tearDown() throws {
        try? FileManager.default.removeItem(atPath: projectPath.string)
    }
    
    static func withTestTool(subfolder: Bool = false, closure: (IntegrationTestTool) async throws -> Void) async throws {
        let tool = try IntegrationTestTool(subfolder: subfolder)
        defer { try? tool.tearDown() }
        try await closure(tool)
    }

    func changeFile(at path: Path) throws {
        let handle = FileHandle(forUpdatingAtPath: path.string)!
        try handle.seekToEnd()
        try handle.write(contentsOf: "\n \n".data(using: .utf8)!)
        try handle.close()

        try runInProject("git add .")
        try runInProject("git commit -m \"Change\"")
    }

    func addFile(at path: Path) throws {
        FileManager().createFile(atPath: path.string, contents: "\n \n".data(using: .utf8)!)

        try runInProject("git add .")
        try runInProject("git commit -m \"Change\"")
    }

    func removeFile(at path: Path) throws {
        try path.delete()

        try runInProject("git add .")
        try runInProject("git commit -m \"Change\"")
    }

    func createSUT(config: Config? = nil,
                   basePath: Path? = nil,
                   testPlan: String? = nil,
                   changedFiles: [String] = [],
                   turbo: Bool = false) throws -> SelectiveTestingTool
    {
        if let config {
            let configText = try config.save()
            let path = projectPath + Config.defaultConfigName
            try configText.write(toFile: path.string, atomically: true, encoding: .utf8)
        }

        let testPlans: [String]
        if let testPlan {
            testPlans = [testPlan]
        }
        else {
            testPlans = []
        }

        let resolvedBasePath: String?
        if let basePath {
            if basePath.isAbsolute {
                resolvedBasePath = basePath.string
            } else {
                resolvedBasePath = (projectPath + basePath).string
            }
        } else if let configBasePath = config?.basePath {
            let configPath = Path(configBasePath)
            if configPath.isAbsolute {
                resolvedBasePath = configPath.string
            } else {
                resolvedBasePath = (projectPath + configPath).string
            }
        } else {
            resolvedBasePath = projectPath.string
        }
        
        return try SelectiveTestingTool(baseBranch: "main",
                                        basePath: resolvedBasePath,
                                        testPlans: testPlans,
                                        changedFiles: changedFiles,
                                        renderDependencyGraph: false,
                                        turbo: turbo,
                                        verbose: true)
    }

    func createSUT() throws -> SelectiveTestingTool {
        return try SelectiveTestingTool(baseBranch: "main",
                                        basePath: (projectPath + "ExampleWorkspace.xcworkspace").string,
                                        testPlans: ["ExampleProject.xctestplan"],
                                        changedFiles: [],
                                        renderDependencyGraph: false,
                                        verbose: true)
    }

    func validateTestPlan(testPlanPath: Path, expected: Set<TargetIdentity>) throws {
        let plan = try TestPlanHelper.readTestPlan(filePath: testPlanPath.string)

        let testPlanTargets: [TargetIdentity] = plan.testTargets.compactMap { target -> TargetIdentity? in
            let container = Path(target.target.containerPath.replacingOccurrences(of: "container:", with: ""))
            let name = target.target.name

            guard target.enabled != false else {
                Issue.record("Unexpected \(target.target.name): disabled targets must be removed")
                return nil
            }

            if container.extension == "xcworkspace" || container.extension == "xcodeproj" {
                return TargetIdentity.project(path: projectPath + container, targetName: name, testTarget: true)
            } else {
                return TargetIdentity.package(path: projectPath + container, targetName: name, testTarget: true)
            }
        }

        #expect(Set(testPlanTargets) == expected)
    }
    
    func checkTestPlanUnmodified(at newPath: Path) throws {
        guard let exampleInBundle = Bundle.module.path(forResource: "ExampleProject", ofType: "") else {
            fatalError("Missing ExampleProject in TestBundle")
        }
        let orignialTestPlanPath = Path(exampleInBundle) + Path(newPath.lastComponent)
        let originalContents = try String(contentsOfFile: orignialTestPlanPath.string)
        
        let newContents = try String(contentsOfFile: newPath.string)
        #expect(originalContents == newContents)
    }

    func mainProjectMainTarget() -> TargetIdentity { TargetIdentity.project(path: projectPath + "ExampleProject.xcodeproj", targetName: "ExampleProject", testTarget: false) }
    func mainProjectTests() -> TargetIdentity { TargetIdentity.project(path: projectPath + "ExampleProject.xcodeproj", targetName: "ExampleProjectTests", testTarget: true) }
    func mainProjectLibrary() -> TargetIdentity { TargetIdentity.project(path: projectPath + "ExampleProject.xcodeproj", targetName: "ExmapleTargetLibrary", testTarget: false) }
    func mainProjectLibraryTests() -> TargetIdentity { TargetIdentity.project(path: projectPath + "ExampleProject.xcodeproj", targetName: "ExmapleTargetLibraryTests", testTarget: true) }
    func mainProjectUITests() -> TargetIdentity { TargetIdentity.project(path: projectPath + "ExampleProject.xcodeproj", targetName: "ExampleProjectUITests", testTarget: true) }
    func exampleLibrary() -> TargetIdentity { TargetIdentity.project(path: projectPath + "ExampleLibrary/ExampleLibrary.xcodeproj", targetName: "ExampleLibrary", testTarget: false) }
    func exampleLibraryTests() -> TargetIdentity { TargetIdentity.project(path: projectPath + "ExampleLibrary/ExampleLibrary.xcodeproj", targetName: "ExampleLibraryTests", testTarget: true) }
    func exampleLibraryInGroup() -> TargetIdentity { TargetIdentity.project(path: projectPath + "Group/ExampleProjectInGroup.xcodeproj", targetName: "ExampleProjectInGroup", testTarget: false) }
    func package() -> TargetIdentity { TargetIdentity.package(path: projectPath + "ExamplePackage", targetName: "ExamplePackage", testTarget: false) }
    func packageTests() -> TargetIdentity { TargetIdentity.package(path: projectPath + "ExamplePackage", targetName: "ExamplePackageTests", testTarget: true) }
    func subtests() -> TargetIdentity { TargetIdentity.package(path: projectPath + "ExamplePackage", targetName: "Subtests", testTarget: true) }
    func binary() -> TargetIdentity { TargetIdentity.package(path: projectPath + "ExamplePackage", targetName: "BinaryTarget", testTarget: false) }
}
