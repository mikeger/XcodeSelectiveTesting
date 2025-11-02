//
//  Created by Mike Gerasymenko <mike@gera.cx>
//

import PathKit
@testable import SelectiveTestingCore
import SelectiveTestShell
import Workspace
import XCTest

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
                                                         testPlans: nil,
                                                         exclude: nil,
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
                                                         testPlans: nil,
                                                         exclude: nil,
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
                                                         testPlans: nil,
                                                         exclude: nil,
                                                         extra: nil))
        // when
        try testTool.changeFile(at: testTool.projectPath + "ExamplePackage/Package.swift")

        // then
        let _ = try await tool.run()
        try testTool.validateTestPlan(testPlanPath: testTool.projectPath + "ExampleProject.xctestplan",
                                      expected: Set([testTool.mainProjectTests,
                                                     testTool.mainProjectUITests,
                                                     testTool.packageTests,
                                                     testTool.subtests]))
    }
    
    func testConfigTestplanPath_packageResolvedChanged() async throws {
        // given
        let tool = try testTool.createSUT(config: Config(basePath: (testTool.projectPath + "ExampleWorkspace.xcworkspace").string,
                                                         testPlan: "ExampleProject.xctestplan",
                                                         testPlans: nil,
                                                         exclude: nil,
                                                         extra: nil))
        // when
        try testTool.addFile(at: testTool.projectPath + "ExamplePackage/Package.resolved")

        // then
        let _ = try await tool.run()
        try testTool.validateTestPlan(testPlanPath: testTool.projectPath + "ExampleProject.xctestplan",
                                      expected: Set([testTool.mainProjectTests,
                                                     testTool.mainProjectUITests,
                                                     testTool.packageTests,
                                                     testTool.subtests]))
    }

    func testAdditionalDependency() async throws {
        // given
        let additionalConfig = WorkspaceInfo.AdditionalConfig(targetsFiles: [:],
                                                              dependencies: ["ExampleProject:ExmapleTargetLibrary": ["ExampleSubpackage:ExampleSubpackage"]])
        let fullConfig = Config(basePath: (testTool.projectPath + "ExampleWorkspace.xcworkspace").string,
                                testPlan: nil,
                                testPlans: nil,
                                exclude: nil,
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
                                testPlans: nil,
                                exclude: nil,
                                extra: additionalConfig)
        let tool = try testTool.createSUT(config: fullConfig)
        // when
        try testTool.addFile(at: testTool.projectPath + "ExmapleTargetLibrary/SomeFile.swift")

        // then
        let result = try await tool.run()
        XCTAssertTrue(result.contains(testTool.mainProjectLibrary))
        XCTAssertTrue(result.contains(testTool.mainProjectLibraryTests))
    }

    func testExclude() async throws {
        // given
        let tool = try testTool.createSUT(config: Config(basePath: (testTool.projectPath + "ExampleWorkspace.xcworkspace").string,
                                                         testPlan: "ExampleProject.xctestplan",
                                                         testPlans: nil,
                                                         exclude: ["ExamplePackage"],
                                                         extra: nil))
        // when
        try testTool.changeFile(at: testTool.projectPath + "ExamplePackage/Package.swift")

        // then
        let _ = try await tool.run()
        try testTool.validateTestPlan(testPlanPath: testTool.projectPath + "ExampleProject.xctestplan",
                                      expected: Set([]))
    }

    func testPackageChangeInDifferentNamedPackage() async throws {
        // given
        let tool = try testTool.createSUT()

        // when
        try testTool.changeFile(at: testTool.projectPath + "ExamplePackage/Tests/Subtests/Test.swift")

        // then
        let _ = try await tool.run()
        try testTool.validateTestPlan(testPlanPath: testTool.projectPath + "ExampleProject.xctestplan",
                                      expected: Set([testTool.subtests]))
    }
    
    func testDryRun() async throws {
        // given
        let tool = try SelectiveTestingTool(baseBranch: "main",
                                            basePath: (testTool.projectPath + "ExampleWorkspace.xcworkspace").string,
                                            testPlans: ["ExampleProject.xctestplan"],
                                            changedFiles: [],
                                            renderDependencyGraph: false,
                                            dryRun: true,
                                            verbose: true)

        // when
        try testTool.changeFile(at: testTool.projectPath + "ExamplePackage/Tests/Subtests/Test.swift")

        // then
        let _ = try await tool.run()
        try testTool.checkTestPlanUnmodified(at: testTool.projectPath + "ExampleProject.xctestplan")
    }

    func testMultipleTestPlansViaCLI() async throws {
        // given
        let tool = try SelectiveTestingTool(baseBranch: "main",
                                            basePath: (testTool.projectPath + "ExampleWorkspace.xcworkspace").string,
                                            testPlans: ["ExampleProject.xctestplan", "ExampleProject2.xctestplan"],
                                            changedFiles: [],
                                            verbose: true)

        // when
        try testTool.changeFile(at: testTool.projectPath + "ExampleLibrary/ExampleLibrary/ExampleLibrary.swift")

        // then
        let result = try await tool.run()
        XCTAssertEqual(result, Set([testTool.mainProjectMainTarget,
                                    testTool.mainProjectTests,
                                    testTool.mainProjectUITests,
                                    testTool.exampleLibrary,
                                    testTool.exampleLibraryTests]))

        // Verify both test plans were updated
        try testTool.validateTestPlan(testPlanPath: testTool.projectPath + "ExampleProject.xctestplan",
                                      expected: Set([testTool.mainProjectTests,
                                                     testTool.mainProjectUITests,
                                                     testTool.exampleLibraryTests]))
        try testTool.validateTestPlan(testPlanPath: testTool.projectPath + "ExampleProject2.xctestplan",
                                      expected: Set([testTool.mainProjectTests,
                                                     testTool.mainProjectUITests,
                                                     testTool.exampleLibraryTests]))
    }

    func testMultipleTestPlansViaConfig() async throws {
        // given
        let tool = try testTool.createSUT(config: Config(basePath: (testTool.projectPath + "ExampleWorkspace.xcworkspace").string,
                                                         testPlan: nil,
                                                         testPlans: ["ExampleProject.xctestplan", "ExampleProject2.xctestplan"],
                                                         exclude: nil,
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

        // Verify both test plans were updated
        try testTool.validateTestPlan(testPlanPath: testTool.projectPath + "ExampleProject.xctestplan",
                                      expected: Set([testTool.mainProjectTests,
                                                     testTool.mainProjectUITests,
                                                     testTool.exampleLibraryTests]))
        try testTool.validateTestPlan(testPlanPath: testTool.projectPath + "ExampleProject2.xctestplan",
                                      expected: Set([testTool.mainProjectTests,
                                                     testTool.mainProjectUITests,
                                                     testTool.exampleLibraryTests]))
    }

    func testMultipleTestPlansMixedCliAndConfig() async throws {
        // given - config has one test plan, CLI adds another
        let tool = try testTool.createSUT(
            config: Config(basePath: (testTool.projectPath + "ExampleWorkspace.xcworkspace").string,
                           testPlan: "ExampleProject.xctestplan",
                           testPlans: nil,
                           exclude: nil,
                           extra: nil),
            testPlan: "ExampleProject2.xctestplan")

        // when
        try testTool.changeFile(at: testTool.projectPath + "ExampleLibrary/ExampleLibrary/ExampleLibrary.swift")

        // then
        let result = try await tool.run()
        XCTAssertEqual(result, Set([testTool.mainProjectMainTarget,
                                    testTool.mainProjectTests,
                                    testTool.mainProjectUITests,
                                    testTool.exampleLibrary,
                                    testTool.exampleLibraryTests]))

        // Verify both test plans were updated
        try testTool.validateTestPlan(testPlanPath: testTool.projectPath + "ExampleProject.xctestplan",
                                      expected: Set([testTool.mainProjectTests,
                                                     testTool.mainProjectUITests,
                                                     testTool.exampleLibraryTests]))
        try testTool.validateTestPlan(testPlanPath: testTool.projectPath + "ExampleProject2.xctestplan",
                                      expected: Set([testTool.mainProjectTests,
                                                     testTool.mainProjectUITests,
                                                     testTool.exampleLibraryTests]))
    }
}
