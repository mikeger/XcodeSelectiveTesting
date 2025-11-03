//
//  Created by Mike Gerasymenko <mike@gera.cx>
//

import PathKit
@testable import SelectiveTestingCore
import SelectiveTestShell
import Testing
import Workspace

@Suite
struct SelectiveTestingProjectTests {
    @Test
    func projectAlone() async throws {
        let testTool = try IntegrationTestTool()
        defer { try? testTool.tearDown() }

        let tool = try testTool.createSUT(config: nil,
                                          basePath: "ExampleProject.xcodeproj")
        try testTool.changeFile(at: testTool.projectPath + "ExampleProject.xcodeproj/project.pbxproj")

        let result = try await tool.run()
        #expect(result == Set([
            testTool.mainProjectMainTarget(),
            testTool.mainProjectTests(),
            testTool.mainProjectUITests(),
            testTool.mainProjectLibrary(),
            testTool.mainProjectLibraryTests(),
        ]))
    }

    @Test
    func projectDeepGroupPathChange_turbo() async throws {
        let testTool = try IntegrationTestTool()
        defer { try? testTool.tearDown() }

        let tool = try testTool.createSUT(config: nil,
                                          basePath: "ExampleProject.xcodeproj",
                                          turbo: true)
        try testTool.changeFile(at: testTool.projectPath + "ExampleProject/DeepGroup/Path/GroupContentView.swift")

        let result = try await tool.run()
        #expect(result == Set([
            testTool.mainProjectMainTarget()
        ]))
    }

    @Test
    func projectDeepGroupPathChange() async throws {
        let testTool = try IntegrationTestTool()
        defer { try? testTool.tearDown() }

        let tool = try testTool.createSUT(config: nil,
                                          basePath: "ExampleProject.xcodeproj")
        try testTool.changeFile(at: testTool.projectPath + "ExampleProject/DeepGroup/Path/GroupContentView.swift")

        let result = try await tool.run()
        #expect(result == Set([
            testTool.mainProjectMainTarget(),
            testTool.mainProjectTests(),
            testTool.mainProjectUITests(),
        ]))
    }

    @Test
    func projectDeepFolderPathChange_turbo() async throws {
        let testTool = try IntegrationTestTool()
        defer { try? testTool.tearDown() }

        let tool = try testTool.createSUT(config: nil,
                                          basePath: "ExampleProject.xcodeproj",
                                          turbo: true)
        try testTool.changeFile(at: testTool.projectPath + "ExampleProject/DeepFolder/Path/FolderContentView.swift")

        let result = try await tool.run()
        #expect(result == Set([
            testTool.mainProjectMainTarget()
        ]))
    }

    @Test
    func projectDeepFolderPathChange() async throws {
        let testTool = try IntegrationTestTool()
        defer { try? testTool.tearDown() }

        let tool = try testTool.createSUT(config: nil,
                                          basePath: "ExampleProject.xcodeproj")
        try testTool.changeFile(at: testTool.projectPath + "ExampleProject/DeepFolder/Path/FolderContentView.swift")

        let result = try await tool.run()
        #expect(result == Set([
            testTool.mainProjectMainTarget(),
            testTool.mainProjectTests(),
            testTool.mainProjectUITests(),
        ]))
    }

    @Test
    func projectLocalizedPathChange() async throws {
        let testTool = try IntegrationTestTool()
        defer { try? testTool.tearDown() }

        let tool = try testTool.createSUT(config: nil,
                                          basePath: "ExampleProject.xcodeproj")
        try testTool.changeFile(at: testTool.projectPath + "ExampleProject/Base.lproj/Example.xib")

        let result = try await tool.run()
        #expect(result == Set([
            testTool.mainProjectMainTarget(),
            testTool.mainProjectTests(),
            testTool.mainProjectUITests(),
        ]))
    }

    @Test
    func passingChangedFiles() async throws {
        let testTool = try IntegrationTestTool()
        defer { try? testTool.tearDown() }

        let changedPath = testTool.projectPath + "ExampleProject/Base.lproj/Example.xib"
        let tool = try testTool.createSUT(config: nil,
                                          basePath: "ExampleProject.xcodeproj",
                                          changedFiles: [changedPath.string])

        let result = try await tool.run()
        #expect(result == Set([
            testTool.mainProjectMainTarget(),
            testTool.mainProjectTests(),
            testTool.mainProjectUITests(),
        ]))
    }
}
