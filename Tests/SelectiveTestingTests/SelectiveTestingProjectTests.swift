//
//  Created by Mike Gerasymenko <mike@gera.cx>
//

import PathKit
@testable import SelectiveTestingCore
import SelectiveTestShell
import Workspace
import XCTest

final class SelectiveTestingProjectTests: XCTestCase {
    let testTool = IntegrationTestTool()

    override func setUp() async throws {
        try await super.setUp()

        try testTool.setUp()
    }

    override func tearDown() async throws {
        try await super.tearDown()

        try testTool.tearDown()
    }

    func testProjectAlone() async throws {
        // given
        let tool = try testTool.createSUT(config: nil,
                                          basePath: "ExampleProject.xcodeproj")
        // when
        try testTool.changeFile(at: testTool.projectPath + "ExampleProject.xcodeproj/project.pbxproj")

        // then
        let result = try await tool.run()
        XCTAssertEqual(result, Set([
            testTool.mainProjectMainTarget,
            testTool.mainProjectTests,
            testTool.mainProjectUITests,
            testTool.mainProjectLibrary,
            testTool.mainProjectLibraryTests,
        ]))
    }

    func testProjectDeepGroupPathChange_turbo() async throws {
        // given
        let tool = try testTool.createSUT(config: nil,
                                          basePath: "ExampleProject.xcodeproj",
                                          turbo: true)
        // when
        try testTool.changeFile(at: testTool.projectPath + "ExampleProject/DeepGroup/Path/GroupContentView.swift")

        // then
        let result = try await tool.run()
        XCTAssertEqual(result, Set([
            testTool.mainProjectMainTarget
        ]))
    }

    func testProjectDeepGroupPathChange() async throws {
        // given
        let tool = try testTool.createSUT(config: nil,
                                          basePath: "ExampleProject.xcodeproj")
        // when
        try testTool.changeFile(at: testTool.projectPath + "ExampleProject/DeepGroup/Path/GroupContentView.swift")

        // then
        let result = try await tool.run()
        XCTAssertEqual(result, Set([
            testTool.mainProjectMainTarget,
            testTool.mainProjectTests,
            testTool.mainProjectUITests,
        ]))
    }

    func testProjectDeepFolderPathChange_turbo() async throws {
        // given
        let tool = try testTool.createSUT(config: nil,
                                          basePath: "ExampleProject.xcodeproj",
                                          turbo: true)
        // when
        try testTool.changeFile(at: testTool.projectPath + "ExampleProject/DeepFolder/Path/FolderContentView.swift")

        // then
        let result = try await tool.run()
        XCTAssertEqual(result, Set([
            testTool.mainProjectMainTarget
        ]))
    }

    func testProjectDeepFolderPathChange() async throws {
        // given
        let tool = try testTool.createSUT(config: nil,
                                          basePath: "ExampleProject.xcodeproj")
        // when
        try testTool.changeFile(at: testTool.projectPath + "ExampleProject/DeepFolder/Path/FolderContentView.swift")

        // then
        let result = try await tool.run()
        XCTAssertEqual(result, Set([
            testTool.mainProjectMainTarget,
            testTool.mainProjectTests,
            testTool.mainProjectUITests,
        ]))
    }

    func testProjectLocalizedPathChange() async throws {
        // given
        let tool = try testTool.createSUT(config: nil,
                                          basePath: "ExampleProject.xcodeproj")
        // when
        try testTool.changeFile(at: testTool.projectPath + "ExampleProject/Base.lproj/Example.xib")

        // then
        let result = try await tool.run()
        XCTAssertEqual(result, Set([
            testTool.mainProjectMainTarget,
            testTool.mainProjectTests,
            testTool.mainProjectUITests,
        ]))
    }
    
    func testPassingChangedFiles() async throws {
        // given & when
        let changedPath = testTool.projectPath + "ExampleProject/Base.lproj/Example.xib"
        let tool = try testTool.createSUT(config: nil,
                                          basePath: "ExampleProject.xcodeproj",
                                          changedFiles: [changedPath.string])

        // then
        let result = try await tool.run()
        XCTAssertEqual(result, Set([
            testTool.mainProjectMainTarget,
            testTool.mainProjectTests,
            testTool.mainProjectUITests,
        ]))
    }
}
