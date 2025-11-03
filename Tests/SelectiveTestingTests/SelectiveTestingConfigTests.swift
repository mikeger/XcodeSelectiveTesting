//
//  Created by Mike Gerasymenko <mike@gera.cx>
//

import PathKit
@testable import SelectiveTestingCore
import SelectiveTestShell
import Testing
import Workspace

@Suite
struct SelectiveTestingConfigTests {
    @Test
    func configWorkspacePath() async throws {
        // given
        let testTool = try IntegrationTestTool()
        defer { try? testTool.tearDown() }

        let tool = try testTool.createSUT(config: Config(basePath: (testTool.projectPath + "ExampleWorkspace.xcworkspace").string,
                                                         testPlan: nil,
                                                         testPlans: nil,
                                                         exclude: nil,
                                                         extra: nil))

        // when
        try testTool.changeFile(at: testTool.projectPath + "ExampleLibrary/ExampleLibrary/ExampleLibrary.swift")

        // then
        let result = try await tool.run()
        #expect(result == Set([testTool.mainProjectMainTarget(),
                               testTool.mainProjectTests(),
                               testTool.mainProjectUITests(),
                               testTool.exampleLibrary(),
                               testTool.exampleLibraryTests()]))
    }

    @Test
    func configTestplanPath() async throws {
        // given
        let testTool = try IntegrationTestTool()
        defer { try? testTool.tearDown() }

        let tool = try testTool.createSUT(config: Config(basePath: (testTool.projectPath + "ExampleWorkspace.xcworkspace").string,
                                                         testPlan: "ExampleProject.xctestplan",
                                                         testPlans: nil,
                                                         exclude: nil,
                                                         extra: nil))

        // when
        try testTool.changeFile(at: testTool.projectPath + "ExampleLibrary/ExampleLibrary/ExampleLibrary.swift")

        // then
        let result = try await tool.run()
        #expect(result == Set([testTool.mainProjectMainTarget(),
                               testTool.mainProjectTests(),
                               testTool.mainProjectUITests(),
                               testTool.exampleLibrary(),
                               testTool.exampleLibraryTests()]))
        try testTool.validateTestPlan(testPlanPath: testTool.projectPath + "ExampleProject.xctestplan",
                                      expected: Set([testTool.mainProjectTests(),
                                                     testTool.mainProjectUITests(),
                                                     testTool.exampleLibraryTests()]))
    }

    @Test
    func configTestplanPath_packageChanged() async throws {
        // given
        let testTool = try IntegrationTestTool()
        
        defer { try? testTool.tearDown() }

        let tool = try testTool.createSUT(config: Config(basePath: (testTool.projectPath + "ExampleWorkspace.xcworkspace").string,
                                                         testPlan: "ExampleProject.xctestplan",
                                                         testPlans: nil,
                                                         exclude: nil,
                                                         extra: nil))

        // when
        try testTool.changeFile(at: testTool.projectPath + "ExamplePackage/Package.swift")

        // then
        _ = try await tool.run()
        try testTool.validateTestPlan(testPlanPath: testTool.projectPath + "ExampleProject.xctestplan",
                                      expected: Set([testTool.mainProjectTests(),
                                                     testTool.mainProjectUITests(),
                                                     testTool.packageTests(),
                                                     testTool.subtests()]))
    }

    @Test
    func configTestplanPath_packageResolvedChanged() async throws {
        // given
        let testTool = try IntegrationTestTool()
        defer { try? testTool.tearDown() }

        let tool = try testTool.createSUT(config: Config(basePath: (testTool.projectPath + "ExampleWorkspace.xcworkspace").string,
                                                         testPlan: "ExampleProject.xctestplan",
                                                         testPlans: nil,
                                                         exclude: nil,
                                                         extra: nil))

        // when
        try testTool.addFile(at: testTool.projectPath + "ExamplePackage/Package.resolved")

        // then
        _ = try await tool.run()
        try testTool.validateTestPlan(testPlanPath: testTool.projectPath + "ExampleProject.xctestplan",
                                      expected: Set([testTool.mainProjectTests(),
                                                     testTool.mainProjectUITests(),
                                                     testTool.packageTests(),
                                                     testTool.subtests()]))
    }

    @Test
    func additionalDependency() async throws {
        // given
        let testTool = try IntegrationTestTool()
        defer { try? testTool.tearDown() }

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
        #expect(result.contains(testTool.mainProjectLibrary()))
        #expect(result.contains(testTool.mainProjectLibraryTests()))
    }

    @Test
    func additionalFiles() async throws {
        // given
        let testTool = try IntegrationTestTool()
        defer { try? testTool.tearDown() }

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
        #expect(result.contains(testTool.mainProjectLibrary()))
        #expect(result.contains(testTool.mainProjectLibraryTests()))
    }

    @Test
    func exclude() async throws {
        // given
        let testTool = try IntegrationTestTool()
        defer { try? testTool.tearDown() }

        let tool = try testTool.createSUT(config: Config(basePath: (testTool.projectPath + "ExampleWorkspace.xcworkspace").string,
                                                         testPlan: "ExampleProject.xctestplan",
                                                         testPlans: nil,
                                                         exclude: ["ExamplePackage"],
                                                         extra: nil))

        // when
        try testTool.changeFile(at: testTool.projectPath + "ExamplePackage/Package.swift")

        // then
        _ = try await tool.run()
        try testTool.validateTestPlan(testPlanPath: testTool.projectPath + "ExampleProject.xctestplan",
                                      expected: Set([]))
    }

    @Test
    func packageChangeInDifferentNamedPackage() async throws {
        // given
        let testTool = try IntegrationTestTool()
        defer { try? testTool.tearDown() }

        let tool = try testTool.createSUT()

        // when
        try testTool.changeFile(at: testTool.projectPath + "ExamplePackage/Tests/Subtests/Test.swift")

        // then
        _ = try await tool.run()
        try testTool.validateTestPlan(testPlanPath: testTool.projectPath + "ExampleProject.xctestplan",
                                      expected: Set([testTool.subtests()]))
    }

    @Test
    func dryRun() async throws {
        // given
        let testTool = try IntegrationTestTool()
        defer { try? testTool.tearDown() }

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
        _ = try await tool.run()
        try testTool.checkTestPlanUnmodified(at: testTool.projectPath + "ExampleProject.xctestplan")
    }

    @Test
    func multipleTestPlansViaCLI() async throws {
        // given
        let testTool = try IntegrationTestTool()
        defer { try? testTool.tearDown() }

        let tool = try SelectiveTestingTool(baseBranch: "main",
                                            basePath: (testTool.projectPath + "ExampleWorkspace.xcworkspace").string,
                                            testPlans: ["ExampleProject.xctestplan", "ExampleProject2.xctestplan"],
                                            changedFiles: [],
                                            verbose: true)

        // when
        try testTool.changeFile(at: testTool.projectPath + "ExampleLibrary/ExampleLibrary/ExampleLibrary.swift")

        // then
        let result = try await tool.run()
        #expect(result == Set([testTool.mainProjectMainTarget(),
                               testTool.mainProjectTests(),
                               testTool.mainProjectUITests(),
                               testTool.exampleLibrary(),
                               testTool.exampleLibraryTests()]))

        try testTool.validateTestPlan(testPlanPath: testTool.projectPath + "ExampleProject.xctestplan",
                                      expected: Set([testTool.mainProjectTests(),
                                                     testTool.mainProjectUITests(),
                                                     testTool.exampleLibraryTests()]))
        try testTool.validateTestPlan(testPlanPath: testTool.projectPath + "ExampleProject2.xctestplan",
                                      expected: Set([testTool.mainProjectTests(),
                                                     testTool.mainProjectUITests(),
                                                     testTool.exampleLibraryTests()]))
    }

    @Test
    func multipleTestPlansViaConfig() async throws {
        // given
        let testTool = try IntegrationTestTool()
        defer { try? testTool.tearDown() }

        let tool = try testTool.createSUT(config: Config(basePath: (testTool.projectPath + "ExampleWorkspace.xcworkspace").string,
                                                         testPlan: nil,
                                                         testPlans: ["ExampleProject.xctestplan", "ExampleProject2.xctestplan"],
                                                         exclude: nil,
                                                         extra: nil))

        // when
        try testTool.changeFile(at: testTool.projectPath + "ExampleLibrary/ExampleLibrary/ExampleLibrary.swift")

        // then
        let result = try await tool.run()
        #expect(result == Set([testTool.mainProjectMainTarget(),
                               testTool.mainProjectTests(),
                               testTool.mainProjectUITests(),
                               testTool.exampleLibrary(),
                               testTool.exampleLibraryTests()]))

        try testTool.validateTestPlan(testPlanPath: testTool.projectPath + "ExampleProject.xctestplan",
                                      expected: Set([testTool.mainProjectTests(),
                                                     testTool.mainProjectUITests(),
                                                     testTool.exampleLibraryTests()]))
        try testTool.validateTestPlan(testPlanPath: testTool.projectPath + "ExampleProject2.xctestplan",
                                      expected: Set([testTool.mainProjectTests(),
                                                     testTool.mainProjectUITests(),
                                                     testTool.exampleLibraryTests()]))
    }

    @Test
    func multipleTestPlansMixedCliAndConfig() async throws {
        // given - config has one test plan, CLI adds another
        let testTool = try IntegrationTestTool()
        defer { try? testTool.tearDown() }

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
        #expect(result == Set([testTool.mainProjectMainTarget(),
                               testTool.mainProjectTests(),
                               testTool.mainProjectUITests(),
                               testTool.exampleLibrary(),
                               testTool.exampleLibraryTests()]))

        try testTool.validateTestPlan(testPlanPath: testTool.projectPath + "ExampleProject.xctestplan",
                                      expected: Set([testTool.mainProjectTests(),
                                                     testTool.mainProjectUITests(),
                                                     testTool.exampleLibraryTests()]))
        try testTool.validateTestPlan(testPlanPath: testTool.projectPath + "ExampleProject2.xctestplan",
                                      expected: Set([testTool.mainProjectTests(),
                                                     testTool.mainProjectUITests(),
                                                     testTool.exampleLibraryTests()]))
    }
}
