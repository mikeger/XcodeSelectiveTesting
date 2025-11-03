//
//  Created by Mike Gerasymenko <mike@gera.cx>
//

import Foundation
import PathKit
@testable import SelectiveTestingCore
import Testing

@Suite
struct SelectiveTestingPerformanceTests {
    @Test
    func performance() async throws {
        let testTool = try IntegrationTestTool()
        defer { try? testTool.tearDown() }

        let tool = try testTool.createSUT()
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
}
