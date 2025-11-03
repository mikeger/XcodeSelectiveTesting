//
//  Created by Mike Gerasymenko <mike@gera.cx>
//

import PathKit
@testable import SelectiveTestingCore
import SelectiveTestShell
import Workspace
import XCTest

final class SelectiveTestingWorksapceTests: XCTestCase {
    let testTool = IntegrationTestTool()

    func testProjectLoading_empty() async throws {
        try await testTool.withTestTool {
            // given
            let tool = try testTool.createSUT()
            // when
            let result = try await tool.run()
            // then
            XCTAssertEqual(result, Set())
        }
    }

    func testProjectLoading_changeLibrary() async throws {
        try await testTool.withTestTool {
            // given
            let tool = try testTool.createSUT()
            // when
            try testTool.changeFile(at: testTool.projectPath + "ExampleLibrary/ExampleLibrary/ExampleLibrary.swift")
            
            // then
            let result = try await tool.run()
            XCTAssertEqual(result, Set([testTool.mainProjectMainTarget,
                                        testTool.mainProjectTests,
                                        testTool.mainProjectUITests,
                                        testTool.exampleLibrary,
                                        testTool.exampleLibraryTests]))
        }
    }

    func testProjectLoading_changeAsset() async throws {
        try await testTool.withTestTool {
            // given
            let tool = try testTool.createSUT()
            // when
            try testTool.changeFile(at: testTool.projectPath + "ExampleProject/Assets.xcassets/Contents.json")
            
            // then
            let result = try await tool.run()
            XCTAssertEqual(result, Set([testTool.mainProjectMainTarget,
                                        testTool.mainProjectTests,
                                        testTool.mainProjectUITests]))
        }
    }

    func testProjectLoading_testPlanChange() async throws {
        try await testTool.withTestTool {
            // given
            let tool = try testTool.createSUT()
            // when
            try testTool.changeFile(at: testTool.projectPath + "ExampleProject.xctestplan")
            
            // then
            let result = try await tool.run()
            XCTAssertEqual(result, Set())
        }
    }

    func testProjectLoading_testWorkspaceFileChange() async throws {
        try await testTool.withTestTool {
            // given
            let tool = try testTool.createSUT()
            // when
            try testTool.changeFile(at: testTool.projectPath + "ExampleWorkspace.xcworkspace/contents.xcworkspacedata")
            // then
            let result = try await tool.run()
            XCTAssertEqual(result, Set([
                testTool.mainProjectMainTarget,
                testTool.mainProjectTests,
                testTool.mainProjectUITests,
                testTool.mainProjectLibrary,
                testTool.mainProjectLibraryTests,
                testTool.exampleLibraryTests,
                testTool.exampleLibrary,
                testTool.exampleLibraryInGroup,
            ]))
        }
    }

    func testProjectLoading_testProjectFileChange() async throws {
        try await testTool.withTestTool {
            // given
            let tool = try testTool.createSUT()
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
    }

    func testInferTestPlan() async throws {
        try await testTool.withTestTool {
            // given
            let tool = try testTool.createSUT(config: nil,
                                              testPlan: nil)
            // when
            try testTool.changeFile(at: testTool.projectPath + "ExampleLibrary/ExampleLibrary/ExampleLibrary.swift")
            
            // then
            let _ = try await tool.run()
            try testTool.validateTestPlan(testPlanPath: testTool.projectPath + "ExampleProject.xctestplan",
                                          expected: Set([testTool.mainProjectTests,
                                                         testTool.mainProjectUITests,
                                                         testTool.exampleLibraryTests]))
        }
    }
    
    func testInferTestPlanInSubfolder() async throws {
        try await testTool.withTestTool(subfolder: true) {
            // given
            let tool = try testTool.createSUT(
                config: nil,
                basePath: testTool.projectPath + "Subfolder",
                testPlan: nil)
            
            // when
            try testTool.changeFile(at: testTool.projectPath + "Subfolder/ExampleLibrary/ExampleLibrary/ExampleLibrary.swift")
            
            // then
            let _ = try await tool.run()
            try testTool.validateTestPlan(testPlanPath: testTool.projectPath + "Subfolder/ExampleProject.xctestplan",
                                          expected: Set([testTool.mainProjectTests,
                                                         testTool.mainProjectUITests,
                                                         testTool.exampleLibraryTests]))
        }
    }
}
