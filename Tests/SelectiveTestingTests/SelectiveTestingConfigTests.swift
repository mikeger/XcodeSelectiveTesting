//
//  Created by Mike Gerasymenko <mike@gera.cx>
//

import XCTest
import PathKit
@testable import SelectiveTestingCore
import Shell
import Workspace

final class SelectiveTestingConfigTests: XCTestCase {
    
    let testTool = IntegrationTestTool()
    
    override func setUp() async throws {
        try await super.setUp()
        
        try testTool.setUp()
    }
    
    override func tearDown() async throws {
        try await super.tearDown()
        
        try testTool.tearDown()
    }
    
    func testConfigWorkspacePath() async throws {
        // given
        let tool = try testTool.createSUT(config: Config(basePath: (testTool.projectPath + "ExampleWorkspace.xcworkspace").string,
                                                         testPlan: nil,
                                                         extra: nil))
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
    
    func testConfigTestplanPath() async throws {
        // given
        let tool = try testTool.createSUT(config: Config(basePath: (testTool.projectPath + "ExampleWorkspace.xcworkspace").string,
                                                         testPlan: "ExampleProject.xctestplan",
                                                         extra: nil))
        // when
        try testTool.changeFile(at: testTool.projectPath + "ExampleLibrary/ExampleLibrary/ExampleLibrary.swift")
        
        // then
        let result = try await tool.run()
        XCTAssertEqual(result, Set([testTool.mainProjectMainTarget,
                                    testTool.mainProjectTests,
                                    testTool.mainProjectUITests,
                                    testTool.exampleLibrary,
                                    testTool.exampleLibraryTests]))
        try testTool.validateTestPlan(testPlanPath: testTool.projectPath + "ExampleProject.xctestplan",
                                      expected: Set([testTool.mainProjectTests,
                                                     testTool.mainProjectUITests,
                                                     testTool.exampleLibraryTests]))
    }
    
    func testConfigTestplanPath_packageChanged() async throws {
        // given
        let tool = try testTool.createSUT(config: Config(basePath: (testTool.projectPath + "ExampleWorkspace.xcworkspace").string,
                                                         testPlan: "ExampleProject.xctestplan",
                                                         extra: nil))
        // when
        try testTool.changeFile(at: testTool.projectPath + "ExamplePackage/Package.swift")
        
        // then
        let _ = try await tool.run()
        try testTool.validateTestPlan(testPlanPath: testTool.projectPath + "ExampleProject.xctestplan",
                                      expected: Set([testTool.mainProjectTests,
                                                     testTool.mainProjectUITests,
                                                     testTool.package]))
    }
    
    func testAdditionalDependency() async throws {
        // given
        let additionalConfig = WorkspaceInfo.AdditionalConfig(targetsFiles: [:],
                                                              dependencies: ["ExampleProject:ExmapleTargetLibrary": ["Package:ExampleSubpackage"]])
        let fullConfig = Config(basePath: (testTool.projectPath + "ExampleWorkspace.xcworkspace").string,
                                testPlan: nil,
                                extra: additionalConfig)
        let tool = try testTool.createSUT(config: fullConfig)
        // when
        try testTool.changeFile(at: testTool.projectPath + "ExampleSubpackage/Package.swift")

        // then
        let result = try await tool.run()
        XCTAssertTrue(result.contains(testTool.mainProjectLibrary))
        XCTAssertTrue(result.contains(testTool.mainProjectLibraryTests))
    }

    func testAdditionalFiles() async throws {
        // given
        let additionalConfig = WorkspaceInfo.AdditionalConfig(targetsFiles: ["ExampleProject:ExmapleTargetLibrary": ["ExmapleTargetLibrary/SomeFile.swift"]],
                                                              dependencies: [:])
        let fullConfig = Config(basePath: (testTool.projectPath + "ExampleWorkspace.xcworkspace").string,
                                testPlan: nil,
                                extra: additionalConfig)
        let tool = try testTool.createSUT(config: fullConfig)
        // when
        try testTool.addFile(at: testTool.projectPath + "ExmapleTargetLibrary/SomeFile.swift")

        // then
        let result = try await tool.run()
        XCTAssertTrue(result.contains(testTool.mainProjectLibrary))
        XCTAssertTrue(result.contains(testTool.mainProjectLibraryTests))
    }
}
