//
//  Created by Mike Gerasymenko <mike@gera.cx>
//

import Foundation
import PathKit
@testable import SelectiveTestingCore
import SelectiveTestShell
import TestConfigurator
import Workspace
import XCTest

final class IntegrationTestTool {
    var projectPath: Path = ""

    func setUp() throws {
        let tmpPath = Path.temporary.absolute()
        guard let exampleInBundle = Bundle.module.path(forResource: "ExampleProject", ofType: "") else {
            fatalError("Missing ExampleProject in TestBundle")
        }
        projectPath = tmpPath + "ExampleProject"
        try? FileManager.default.removeItem(atPath: projectPath.string)
        try FileManager.default.copyItem(atPath: exampleInBundle, toPath: projectPath.string)
        FileManager.default.changeCurrentDirectoryPath(projectPath.string)
        try Shell.execOrFail("git init")
        try Shell.execOrFail("git config commit.gpgsign false")
        try Shell.execOrFail("git checkout -b main")
        try Shell.execOrFail("git add .")
        try Shell.execOrFail("git commit -m \"Base\"")
        try Shell.execOrFail("git checkout -b feature")
    }

    func tearDown() throws {
        try? FileManager.default.removeItem(atPath: projectPath.string)
    }

    func changeFile(at path: Path) throws {
        let handle = FileHandle(forUpdatingAtPath: path.string)!
        try handle.seekToEnd()
        try handle.write(contentsOf: "\n \n".data(using: .utf8)!)
        try handle.close()

        try Shell.execOrFail("git add .")
        try Shell.execOrFail("git commit -m \"Change\"")
    }

    func addFile(at path: Path) throws {
        FileManager().createFile(atPath: path.string, contents: "\n \n".data(using: .utf8)!)

        try Shell.execOrFail("git add .")
        try Shell.execOrFail("git commit -m \"Change\"")
    }

    func removeFile(at path: Path) throws {
        try path.delete()

        try Shell.execOrFail("git add .")
        try Shell.execOrFail("git commit -m \"Change\"")
    }

    func createSUT(config: Config? = nil,
                   basePath: Path? = nil,
                   testPlan: String? = nil,
                   changedFiles: [String] = [],
                   turbo: Bool = false) throws -> SelectiveTestingTool
    {
        if let config {
            let configText = try config.save()
            let path = Path.current + Config.defaultConfigName
            try configText.write(toFile: path.string, atomically: true, encoding: .utf8)
        }

        return try SelectiveTestingTool(baseBranch: "main",
                                        basePath: basePath?.string,
                                        testPlan: testPlan,
                                        changedFiles: changedFiles,
                                        renderDependencyGraph: false,
                                        turbo: turbo,
                                        verbose: true)
    }

    func createSUT() throws -> SelectiveTestingTool {
        return try SelectiveTestingTool(baseBranch: "main",
                                        basePath: (projectPath + "ExampleWorkspace.xcworkspace").string,
                                        testPlan: "ExampleProject.xctestplan",
                                        changedFiles: [],
                                        renderDependencyGraph: false,
                                        verbose: true)
    }

    func validateTestPlan(testPlanPath: Path, expected: Set<TargetIdentity>) throws {
        let plan = try TestPlanHelper.readTestPlan(filePath: testPlanPath.string)

        let testPlanTargets: [TargetIdentity] = plan.testTargets.compactMap { target -> TargetIdentity? in
            let container = Path(target.target.containerPath.replacingOccurrences(of: "container:", with: ""))
            let name = target.target.name

            guard target.enabled ?? true else {
                XCTFail("Unexpected \(target.target.name): disabled targets must be removed")
                return nil
            }

            if container.extension == "xcworkspace" || container.extension == "xcodeproj" {
                return TargetIdentity.project(path: projectPath + container, targetName: name, testTarget: true)
            } else {
                return TargetIdentity.package(path: projectPath + container, targetName: name, testTarget: true)
            }
        }

        XCTAssertEqual(Set(testPlanTargets), expected)
    }
    
    func checkTestPlanUnmodified(at newPath: Path) throws {
        guard let exampleInBundle = Bundle.module.path(forResource: "ExampleProject", ofType: "") else {
            fatalError("Missing ExampleProject in TestBundle")
        }
        let orignialTestPlanPath = Path(exampleInBundle) + Path(newPath.lastComponent)
        let originalContents = try String(contentsOfFile: orignialTestPlanPath.string)
        
        let newContents = try String(contentsOfFile: newPath.string)
        XCTAssertEqual(originalContents, newContents)
    }

    lazy var mainProjectMainTarget = TargetIdentity.project(path: projectPath + "ExampleProject.xcodeproj", targetName: "ExampleProject", testTarget: false)
    lazy var mainProjectTests = TargetIdentity.project(path: projectPath + "ExampleProject.xcodeproj", targetName: "ExampleProjectTests", testTarget: true)
    lazy var mainProjectLibrary = TargetIdentity.project(path: projectPath + "ExampleProject.xcodeproj", targetName: "ExmapleTargetLibrary", testTarget: false)
    lazy var mainProjectLibraryTests = TargetIdentity.project(path: projectPath + "ExampleProject.xcodeproj", targetName: "ExmapleTargetLibraryTests", testTarget: true)
    lazy var mainProjectUITests = TargetIdentity.project(path: projectPath + "ExampleProject.xcodeproj", targetName: "ExampleProjectUITests", testTarget: true)
    lazy var exampleLibrary = TargetIdentity.project(path: projectPath + "ExampleLibrary/ExampleLibrary.xcodeproj", targetName: "ExampleLibrary", testTarget: false)
    lazy var exampleLibraryTests = TargetIdentity.project(path: projectPath + "ExampleLibrary/ExampleLibrary.xcodeproj", targetName: "ExampleLibraryTests", testTarget: true)
    lazy var exampleLibraryInGroup = TargetIdentity.project(path: projectPath + "Group/ExampleProjectInGroup.xcodeproj", targetName: "ExampleProjectInGroup", testTarget: false)
    lazy var package = TargetIdentity.package(path: projectPath + "ExamplePackage", targetName: "ExamplePackage", testTarget: false)
    lazy var packageTests = TargetIdentity.package(path: projectPath + "ExamplePackage", targetName: "ExamplePackageTests", testTarget: true)
    lazy var subtests = TargetIdentity.package(path: projectPath + "ExamplePackage", targetName: "Subtests", testTarget: true)
    lazy var binary = TargetIdentity.package(path: projectPath + "ExamplePackage", targetName: "BinaryTarget", testTarget: false)
}
