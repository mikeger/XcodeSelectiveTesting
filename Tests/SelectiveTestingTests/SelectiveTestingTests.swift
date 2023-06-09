//
//  Created by Mike Gerasymenko <mike@gera.cx>
//

import XCTest
import PathKit
@testable import SelectiveTestingCore
import Shell
import Workspace

final class ProjectLoadingTests: XCTestCase {
    var projectPath: Path = ""
    
    override func setUp() async throws {
        try await super.setUp()
        
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
    
    override func tearDown() async throws {
        try await super.tearDown()
        
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
    
    func createTool() -> SelectiveTestingTool {
        return SelectiveTestingTool(baseBranch: "main",
                                    projectWorkspacePath: (projectPath + "ExampleWorkspace.xcworkspace").string,
                                    testPlan: "ExampleProject.xctestplan",
                                    printJSON: true,
                                    renderDependencyGraph: false)
    }
    
    lazy var mainProjectMainTarget = TargetIdentity(projectPath: projectPath + "ExampleProject.xcodeproj", targetName: "ExampleProject")
    lazy var mainProjectTests = TargetIdentity(projectPath: projectPath + "ExampleProject.xcodeproj", targetName: "ExampleProjectTests")
    lazy var mainProjectLibrary = TargetIdentity(projectPath: projectPath + "ExampleProject.xcodeproj", targetName: "ExmapleTargetLibrary")
    lazy var mainProjectLibraryTests = TargetIdentity(projectPath: projectPath + "ExampleProject.xcodeproj", targetName: "ExmapleTargetLibraryTests")
    lazy var mainProjectUITests = TargetIdentity(projectPath: projectPath + "ExampleProject.xcodeproj", targetName: "ExampleProjectUITests")
    lazy var exampleLibrary = TargetIdentity(projectPath: projectPath + "ExampleLibrary/ExampleLibrary.xcodeproj", targetName: "ExampleLibrary")
    lazy var exampleLibraryTests = TargetIdentity(projectPath: projectPath + "ExampleLibrary/ExampleLibrary.xcodeproj", targetName: "ExampleLibraryTests")
    lazy var package = TargetIdentity.swiftPackage(path: projectPath + "ExamplePackage/Package.swift", name: "ExamplePackage")
    
    func testProjectLoading_empty() async throws {
        // given
        let tool = createTool()
        // when
        let result = try await tool.run()
        // then
        XCTAssertEqual(result, Set())
    }
    
    func testProjectLoading_changeLibrary() async throws {
        // given
        let tool = createTool()
        // when
        try changeFile(at: projectPath + "ExampleLibrary/ExampleLibrary/ExampleLibrary.swift")
        
        // then
        let result = try await tool.run()
        XCTAssertEqual(result, Set([mainProjectMainTarget,
                                    mainProjectTests,
                                    mainProjectUITests,
                                    exampleLibrary,
                                    exampleLibraryTests]))
    }
    
    func testProjectLoading_changePackage() async throws {
        // given
        let tool = createTool()
        // when
        try changeFile(at: projectPath + "ExamplePackage/Sources/ExamplePackage/ExamplePackage.swift")
        
        // then
        let result = try await tool.run()
        XCTAssertEqual(result, Set([mainProjectMainTarget, mainProjectTests, mainProjectUITests, package]))
    }
    
    func testProjectLoading_changeAsset() async throws {
        // given
        let tool = createTool()
        // when
        try changeFile(at: projectPath + "ExampleProject/Assets.xcassets/Contents.json")
        
        // then
        let result = try await tool.run()
        XCTAssertEqual(result, Set([mainProjectMainTarget, mainProjectTests, mainProjectUITests]))
    }
    
    func testProjectLoading_testPlanChange() async throws {
        // given
        let tool = createTool()
        // when
        try changeFile(at: projectPath + "ExampleProject.xctestplan")
        
        // then
        let result = try await tool.run()
        XCTAssertEqual(result, Set())
    }
    
    func testProjectLoading_testWorkspaceFileChange() async throws {
        // given
        let tool = createTool()
        // when
        try changeFile(at: projectPath + "ExampleWorkspace.xcworkspace/contents.xcworkspacedata")
        // then
        let result = try await tool.run()
        XCTAssertEqual(result, Set([
            mainProjectMainTarget,
            mainProjectTests,
            mainProjectUITests,
            mainProjectLibrary,
            mainProjectLibraryTests,
            exampleLibraryTests,
            exampleLibrary
        ]))
    }
    
    func testProjectLoading_testProjectFileChange() async throws {
        // given
        let tool = createTool()
        // when
        try changeFile(at: projectPath + "ExampleProject.xcodeproj/project.pbxproj")
        
        // then
        let result = try await tool.run()
        XCTAssertEqual(result, Set([
            mainProjectMainTarget,
            mainProjectTests,
            mainProjectUITests,
            mainProjectLibrary,
            mainProjectLibraryTests
        ]))
    }
}
