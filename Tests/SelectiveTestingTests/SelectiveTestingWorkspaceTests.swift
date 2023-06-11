//
//  Created by Mike Gerasymenko <mike@gera.cx>
//

import XCTest
import PathKit
@testable import SelectiveTestingCore
import Shell
import Workspace

final class SelectiveTestingWorksapceTests: XCTestCase {
    let testTool = IntegrationTestTool()
    
    override func setUp() async throws {
        try await super.setUp()
        
        try testTool.setUp()
    }
    
    override func tearDown() async throws {
        try await super.tearDown()
        
        try testTool.tearDown()
    }
    
    func testProjectLoading_empty() async throws {
        // given
        let tool = try testTool.createSUT()
        // when
        let result = try await tool.run()
        // then
        XCTAssertEqual(result, Set())
    }
    
    func testProjectLoading_changeLibrary() async throws {
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
    
    func testProjectLoading_changeAsset() async throws {
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
    
    func testProjectLoading_testPlanChange() async throws {
        // given
        let tool = try testTool.createSUT()
        // when
        try testTool.changeFile(at: testTool.projectPath + "ExampleProject.xctestplan")
        
        // then
        let result = try await tool.run()
        XCTAssertEqual(result, Set())
    }
    
    func testProjectLoading_testWorkspaceFileChange() async throws {
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
            testTool.exampleLibrary
        ]))
    }
    
    func testProjectLoading_testProjectFileChange() async throws {
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
            testTool.mainProjectLibraryTests
        ]))
    }
    
    func testInferTestPlan() async throws {
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
