import PathKit
@testable import SelectiveTestingCore
import Testing
import Workspace

@Suite
struct SelectiveTestingJSONProjectTests {
    @Test
    func projectDefinitionChange() async throws {
        let fixture = try IntegrationTestTool(jsonFormat: true)
        defer { try? fixture.tearDown() }
        let tool = try fixture.createSUT(basePath: "ExampleProject.xcodeproj")

        try fixture.changeFile(at: fixture.projectPath + "ExampleProject.xcodeproj/project.xcproj")

        let result = try await tool.run()
        #expect(result == Set([
            fixture.mainProjectMainTarget(), fixture.mainProjectTests(),
            fixture.mainProjectUITests(), fixture.mainProjectLibrary(),
            fixture.mainProjectLibraryTests(),
        ]))
    }

    @Test
    func projectSourceChange() async throws {
        let fixture = try IntegrationTestTool(jsonFormat: true)
        defer { try? fixture.tearDown() }
        let tool = try fixture.createSUT(basePath: "ExampleProject.xcodeproj", turbo: true)

        try fixture.changeFile(at: fixture.projectPath + "ExampleProject/DeepFolder/Path/FolderContentView.swift")

        let result = try await tool.run()
        #expect(result == Set([
            fixture.mainProjectMainTarget(), fixture.mainProjectTests(), fixture.mainProjectUITests(),
        ]))
    }

    @Test
    func workspaceLibraryChangeAndTestPlan() async throws {
        let fixture = try IntegrationTestTool(jsonFormat: true)
        defer { try? fixture.tearDown() }
        let tool = try fixture.createSUT(basePath: "ExampleWorkspace.xcworkspace")

        try fixture.changeFile(at: fixture.projectPath + "ExampleLibrary/ExampleLibrary/ExampleLibrary.swift")

        let result = try await tool.run()
        #expect(result == Set([
            fixture.mainProjectMainTarget(), fixture.mainProjectTests(), fixture.mainProjectUITests(),
            fixture.exampleLibrary(), fixture.exampleLibraryTests(),
        ]))
        try fixture.validateTestPlan(testPlanPath: fixture.projectPath + "ExampleProject.xctestplan",
                                     expected: Set([fixture.mainProjectTests(), fixture.mainProjectUITests(), fixture.exampleLibraryTests()]))
    }
}
