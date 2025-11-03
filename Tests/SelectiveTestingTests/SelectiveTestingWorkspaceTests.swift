//
//  Created by Mike Gerasymenko <mike@gera.cx>
//

import PathKit
@testable import SelectiveTestingCore
import SelectiveTestShell
import Testing
import Workspace

@Suite
struct SelectiveTestingWorkspaceTests {
    @Test
    func projectLoading_empty() async throws {
        try await IntegrationTestTool.withTestTool { testTool in
            let tool = try testTool.createSUT()
            let result = try await tool.run()
            #expect(result == Set())
        }
    }

    @Test
    func projectLoading_changeLibrary() async throws {
        try await IntegrationTestTool.withTestTool { testTool in
            let tool = try testTool.createSUT()
            try testTool.changeFile(at: testTool.projectPath + "ExampleLibrary/ExampleLibrary/ExampleLibrary.swift")

            let result = try await tool.run()
            #expect(result == Set([testTool.mainProjectMainTarget(),
                                   testTool.mainProjectTests(),
                                   testTool.mainProjectUITests(),
                                   testTool.exampleLibrary(),
                                   testTool.exampleLibraryTests()]))
        }
    }

    @Test
    func projectLoading_changeAsset() async throws {
        try await IntegrationTestTool.withTestTool { testTool in
            let tool = try testTool.createSUT()
            try testTool.changeFile(at: testTool.projectPath + "ExampleProject/Assets.xcassets/Contents.json")

            let result = try await tool.run()
            #expect(result == Set([testTool.mainProjectMainTarget(),
                                   testTool.mainProjectTests(),
                                   testTool.mainProjectUITests()]))
        }
    }

    @Test
    func projectLoading_testPlanChange() async throws {
        try await IntegrationTestTool.withTestTool { testTool in
            let tool = try testTool.createSUT()
            try testTool.changeFile(at: testTool.projectPath + "ExampleProject.xctestplan")

            let result = try await tool.run()
            #expect(result == Set())
        }
    }

    @Test
    func projectLoading_testWorkspaceFileChange() async throws {
        try await IntegrationTestTool.withTestTool { testTool in
            let tool = try testTool.createSUT()
            try testTool.changeFile(at: testTool.projectPath + "ExampleWorkspace.xcworkspace/contents.xcworkspacedata")

            let result = try await tool.run()
            #expect(result == Set([
                testTool.mainProjectMainTarget(),
                testTool.mainProjectTests(),
                testTool.mainProjectUITests(),
                testTool.mainProjectLibrary(),
                testTool.mainProjectLibraryTests(),
                testTool.exampleLibraryTests(),
                testTool.exampleLibrary(),
                testTool.exampleLibraryInGroup()
            ]))
        }
    }

    @Test
    func projectLoading_testProjectFileChange() async throws {
        try await IntegrationTestTool.withTestTool { testTool in
            try testTool.changeFile(at: testTool.projectPath + "ExampleProject.xcodeproj/project.pbxproj")
            let tool = try testTool.createSUT()
            let result = try await tool.run()
            #expect(result == Set([
                testTool.mainProjectMainTarget(),
                testTool.mainProjectTests(),
                testTool.mainProjectUITests(),
                testTool.mainProjectLibrary(),
                testTool.mainProjectLibraryTests(),
            ]))
        }
    }

    @Test
    func inferTestPlan() async throws {
        try await IntegrationTestTool.withTestTool { testTool in
            let tool = try testTool.createSUT(config: nil,
                                              testPlan: nil)
            try testTool.changeFile(at: testTool.projectPath + "ExampleLibrary/ExampleLibrary/ExampleLibrary.swift")

            _ = try await tool.run()
            try testTool.validateTestPlan(testPlanPath: testTool.projectPath + "ExampleProject.xctestplan",
                                          expected: Set([testTool.mainProjectTests(),
                                                         testTool.mainProjectUITests(),
                                                         testTool.exampleLibraryTests()]))
        }
    }

    @Test
    func inferTestPlanInSubfolder() async throws {
        try await IntegrationTestTool.withTestTool(subfolder: true) { testTool in
            let tool = try testTool.createSUT(
                config: nil,
                basePath: testTool.projectPath + "Subfolder",
                testPlan: nil)

            try testTool.changeFile(at: testTool.projectPath + "Subfolder/ExampleLibrary/ExampleLibrary/ExampleLibrary.swift")

            _ = try await tool.run()
            try testTool.validateTestPlan(testPlanPath: testTool.projectPath + "Subfolder/ExampleProject.xctestplan",
                                          expected: Set([testTool.mainProjectTests(),
                                                         testTool.mainProjectUITests(),
                                                         testTool.exampleLibraryTests()]))
        }
    }
}
