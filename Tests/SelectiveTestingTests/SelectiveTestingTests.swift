//
//  Created by Mike Gerasymenko <mike@gera.cx>
//

import XCTest
import PathKit
@testable import SelectiveTestingCore
import Shell

final class ProjectLoadingTests: XCTestCase {
    var projectPath: String = ""
    
    override func setUp() async throws {
        try await super.setUp()
        
        let tmpPath = Path.temporary
        guard let exampleInBundle = Bundle.module.path(forResource: "ExampleProject", ofType: "") else {
            fatalError("Missing ExampleProject in TestBundle")
        }
        projectPath = tmpPath.string.appending("ExampleProject")
        try? FileManager.default.removeItem(atPath: projectPath)
        try FileManager.default.copyItem(atPath: exampleInBundle, toPath: projectPath)
        FileManager.default.changeCurrentDirectoryPath(projectPath)
        try Shell.exec("git init")
        try Shell.exec("git add .")
        try Shell.exec("git commit -m \"Base\"")
    }
    
    func testProjectLoading_empty() async throws {
        // given
        let tool = SelectiveTestingTool(baseBranch: "main",
                                        projectWorkspacePath: projectPath.appending("/ExampleProject.xcodeproj"),
                                        renderDependencyGraph: true)
        // when
        let result = try await tool.run()
        // then
        XCTAssertEqual(result, Set())
    }
}
