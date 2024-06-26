//
//  Created by Mike Gerasymenko <mike@gera.cx>
//

import Foundation
import PathKit
@testable import SelectiveTestingCore
import XCTest

final class SelectiveTestingPerformanceTests: XCTestCase {
    let testTool = IntegrationTestTool()

    override func setUp() async throws {
        try await super.setUp()

        try testTool.setUp()
    }

    override func tearDown() async throws {
        try await super.tearDown()

        try testTool.tearDown()
    }

    func testPerformance() async throws {
        measure {
            let expecation = expectation(description: "Job is done")
            Task {
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
                    testTool.mainProjectLibraryTests,
                ]))
                expecation.fulfill()
            }

            wait(for: [expecation], timeout: 2000)
        }
    }
}
