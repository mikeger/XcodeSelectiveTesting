//
//  Created by Mike Gerasymenko <mike@gera.cx>
//

import Foundation
import PathKit
@testable import SelectiveTestingCore
import SelectiveTestShell
import Testing
import Workspace

@Suite
struct SelectiveTestingProjectTests {
    @Test
    func projectAlone() async throws {
        // given
        let testTool = try IntegrationTestTool()
        defer { try? testTool.tearDown() }

        let tool = try testTool.createSUT(config: nil,
                                          basePath: "ExampleProject.xcodeproj")

        // when
        try testTool.changeFile(at: testTool.projectPath + "ExampleProject.xcodeproj/project.pbxproj")

        // then
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
    func projectBasePathWithSpaces() async throws {
        // given
        let testTool = try IntegrationTestTool()
        defer { try? testTool.tearDown() }

        let projectRoot = testTool.projectPath.string.shellQuoted
        let originalName = "ExampleProject.xcodeproj"
        let spacedName = "Example Project.xcodeproj"
        try Shell.execOrFail("(cd \(projectRoot) && git checkout main)")
        try Shell.execOrFail("(cd \(projectRoot) && git mv \(originalName.shellQuoted) \(spacedName.shellQuoted))")
        try Shell.execOrFail("(cd \(projectRoot) && git commit -m 'Rename project with spaces')")
        try Shell.execOrFail("(cd \(projectRoot) && git checkout feature)")
        try Shell.execOrFail("(cd \(projectRoot) && git merge main)")

        let renamedProject = testTool.projectPath + spacedName
        let tool = try testTool.createSUT(config: nil,
                                          basePath: renamedProject)

        // when
        try testTool.changeFile(at: renamedProject + "project.pbxproj")

        // then
        let result = try await tool.run()
        let expectedTargets: Set<TargetIdentity> = Set([
            TargetIdentity.project(path: renamedProject, targetName: "ExampleProject", testTarget: false),
            TargetIdentity.project(path: renamedProject, targetName: "ExampleProjectTests", testTarget: true),
            TargetIdentity.project(path: renamedProject, targetName: "ExampleProjectUITests", testTarget: true),
            TargetIdentity.project(path: renamedProject, targetName: "ExmapleTargetLibrary", testTarget: false),
            TargetIdentity.project(path: renamedProject, targetName: "ExmapleTargetLibraryTests", testTarget: true),
        ])
        #expect(result == expectedTargets)
    }

    @Test
    func projectDeepGroupPathChange_turbo() async throws {
        // given
        let testTool = try IntegrationTestTool()
        defer { try? testTool.tearDown() }

        let tool = try testTool.createSUT(config: nil,
                                          basePath: "ExampleProject.xcodeproj",
                                          turbo: true)

        // when
        try testTool.changeFile(at: testTool.projectPath + "ExampleProject/DeepGroup/Path/GroupContentView.swift")

        // then
        let result = try await tool.run()
        #expect(result == Set([
            testTool.mainProjectMainTarget()
        ]))
    }

    @Test
    func projectDeepGroupPathChange() async throws {
        // given
        let testTool = try IntegrationTestTool()
        defer { try? testTool.tearDown() }

        let tool = try testTool.createSUT(config: nil,
                                          basePath: "ExampleProject.xcodeproj")

        // when
        try testTool.changeFile(at: testTool.projectPath + "ExampleProject/DeepGroup/Path/GroupContentView.swift")

        // then
        let result = try await tool.run()
        #expect(result == Set([
            testTool.mainProjectMainTarget(),
            testTool.mainProjectTests(),
            testTool.mainProjectUITests(),
        ]))
    }

    @Test
    func projectDeepFolderPathChange_turbo() async throws {
        // given
        let testTool = try IntegrationTestTool()
        defer { try? testTool.tearDown() }

        let tool = try testTool.createSUT(config: nil,
                                          basePath: "ExampleProject.xcodeproj",
                                          turbo: true)

        // when
        try testTool.changeFile(at: testTool.projectPath + "ExampleProject/DeepFolder/Path/FolderContentView.swift")

        // then
        let result = try await tool.run()
        #expect(result == Set([
            testTool.mainProjectMainTarget()
        ]))
    }

    @Test
    func projectDeepFolderPathChange() async throws {
        // given
        let testTool = try IntegrationTestTool()
        defer { try? testTool.tearDown() }

        let tool = try testTool.createSUT(config: nil,
                                          basePath: "ExampleProject.xcodeproj")

        // when
        try testTool.changeFile(at: testTool.projectPath + "ExampleProject/DeepFolder/Path/FolderContentView.swift")

        // then
        let result = try await tool.run()
        #expect(result == Set([
            testTool.mainProjectMainTarget(),
            testTool.mainProjectTests(),
            testTool.mainProjectUITests(),
        ]))
    }

    @Test
    func projectLocalizedPathChange() async throws {
        // given
        let testTool = try IntegrationTestTool()
        defer { try? testTool.tearDown() }

        let tool = try testTool.createSUT(config: nil,
                                          basePath: "ExampleProject.xcodeproj")

        // when
        try testTool.changeFile(at: testTool.projectPath + "ExampleProject/Base.lproj/Example.xib")

        // then
        let result = try await tool.run()
        #expect(result == Set([
            testTool.mainProjectMainTarget(),
            testTool.mainProjectTests(),
            testTool.mainProjectUITests(),
        ]))
    }

    @Test
    func passingChangedFiles() async throws {
        // given & when
        let testTool = try IntegrationTestTool()
        defer { try? testTool.tearDown() }

        let changedPath = testTool.projectPath + "ExampleProject/Base.lproj/Example.xib"
        let tool = try testTool.createSUT(config: nil,
                                          basePath: "ExampleProject.xcodeproj",
                                          changedFiles: [changedPath.string])

        // then
        let result = try await tool.run()
        #expect(result == Set([
            testTool.mainProjectMainTarget(),
            testTool.mainProjectTests(),
            testTool.mainProjectUITests(),
        ]))
    }
}
