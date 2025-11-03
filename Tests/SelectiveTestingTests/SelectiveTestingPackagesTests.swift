//
//  Created by Mike Gerasymenko <mike@gera.cx>
//

import PathKit
@testable import SelectiveTestingCore
import SelectiveTestShell
import Testing
import Workspace

@Suite
struct SelectiveTestingPackagesTests {
    @Test
    func projectLoading_changePackage() async throws {
        // given
        let testTool = try IntegrationTestTool()
        defer { try? testTool.tearDown() }

        let tool = try testTool.createSUT()

        // when
        try testTool.changeFile(at: testTool.projectPath + "ExamplePackage/Sources/ExamplePackage/ExamplePackage.swift")

        // then
        let result = try await tool.run()
        #expect(result == Set([testTool.mainProjectMainTarget(),
                               testTool.mainProjectTests(),
                               testTool.mainProjectUITests(),
                               testTool.package(),
                               testTool.packageTests(),
                               testTool.subtests()]))
    }

    @Test
    func projectLoading_changePackageDefinition() async throws {
        // given
        let testTool = try IntegrationTestTool()
        defer { try? testTool.tearDown() }

        let tool = try testTool.createSUT()

        // when
        try testTool.changeFile(at: testTool.projectPath + "ExamplePackage/Package.swift")

        // then
        let result = try await tool.run()
        #expect(result == Set([testTool.mainProjectMainTarget(),
                               testTool.mainProjectTests(),
                               testTool.mainProjectUITests(),
                               testTool.package(),
                               testTool.packageTests(),
                               testTool.subtests(),
                               testTool.binary()]))
    }

    @Test
    func projectLoading_packageAddFile() async throws {
        // given
        let testTool = try IntegrationTestTool()
        defer { try? testTool.tearDown() }

        let tool = try testTool.createSUT()

        // when
        try testTool.addFile(at: testTool.projectPath + "ExamplePackage/Sources/ExamplePackage/ExamplePackageFile.swift")

        // then
        let result = try await tool.run()
        #expect(result == Set([testTool.mainProjectMainTarget(),
                               testTool.mainProjectTests(),
                               testTool.mainProjectUITests(),
                               testTool.package(),
                               testTool.packageTests(),
                               testTool.subtests()]))
    }

    @Test
    func projectLoading_packageRemoveFile() async throws {
        // given
        let testTool = try IntegrationTestTool()
        defer { try? testTool.tearDown() }

        let tool = try testTool.createSUT()

        // when
        try testTool.removeFile(at: testTool.projectPath + "ExamplePackage/Sources/ExamplePackage/ExamplePackage.swift")

        // then
        let result = try await tool.run()
        #expect(result == Set([testTool.mainProjectMainTarget(),
                               testTool.mainProjectTests(),
                               testTool.mainProjectUITests(),
                               testTool.package(),
                               testTool.packageTests(),
                               testTool.subtests()]))
    }

    @Test
    func binaryTargetChange() async throws {
        // given
        let testTool = try IntegrationTestTool()
        defer { try? testTool.tearDown() }

        let tool = try testTool.createSUT()

        // when
        try testTool.changeFile(at: testTool.projectPath + "ExamplePackage/Binary.xcframework/Info.plist")

        // then
        let result = try await tool.run()
        #expect(result == Set([testTool.binary()]))
    }
}
