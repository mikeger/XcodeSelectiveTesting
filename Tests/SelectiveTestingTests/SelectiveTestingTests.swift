//
//  Created by Mike Gerasymenko <mike@gera.cx>
//

import XCTest
import PathKit
@testable import SelectiveTestingCore
import Shell
import Workspace

final class ProjectLoadingTests: XCTestCase {
    var projectPath: Path = ""
    
    override func setUp() async throws {
        try await super.setUp()
        
        let tmpPath = Path.temporary
        guard let exampleInBundle = Bundle.module.path(forResource: "ExampleProject", ofType: "") else {
            fatalError("Missing ExampleProject in TestBundle")
        }
        projectPath = tmpPath + "ExampleProject"
        try? FileManager.default.removeItem(atPath: projectPath.string)
        try FileManager.default.copyItem(atPath: exampleInBundle, toPath: projectPath.string)
        FileManager.default.changeCurrentDirectoryPath(projectPath.string)
        try Shell.execOrFail("git init")
        try Shell.execOrFail("git config commit.gpgsign false")
        try Shell.execOrFail("git add .")
        try Shell.execOrFail("git commit -m \"Base\"")
        try Shell.execOrFail("git checkout -b feature")
    }
    
    override func tearDown() async throws {
        try await super.tearDown()
        
        try? FileManager.default.removeItem(atPath: projectPath.string)
    }
    
    func changeFile(at path: Path) throws {
        let handle = FileHandle(forUpdatingAtPath: path.string)!
        try handle.seekToEnd()
        try handle.write(contentsOf: "\n// change".data(using: .utf8)!)
        try handle.close()
        
        try Shell.execOrFail("git add .")
        try Shell.execOrFail("git commit -m \"Change\"")
    }
    
    func testProjectLoading_empty() async throws {
        // given
        let tool = SelectiveTestingTool(baseBranch: "main",
                                        projectWorkspacePath: (projectPath + "ExampleWorkspace.xcworkspace").string,
                                        scheme: "ExampleProject",
                                        renderDependencyGraph: false)
        // when
        let result = try await tool.run()
        // then
        XCTAssertEqual(result, Set())
    }
    
    func testProjectLoading_changeLibrary() async throws {
        // given
        let tool = SelectiveTestingTool(baseBranch: "main",
                                        projectWorkspacePath: (projectPath + "ExampleWorkspace.xcworkspace").string,
                                        scheme: "ExampleProject",
                                        renderDependencyGraph: false)
        // when
        try changeFile(at: projectPath + "ExampleLibrary/ExampleLibrary/ExampleLibrary.swift")
        
        // then
        let result = try await tool.run()
        XCTAssertEqual(result, Set([TargetIdentity(projectPath: projectPath + "ExampleLibrary/ExampleLibrary.xcodeproj", targetName: "ExampleLibrary"),
                                    TargetIdentity(projectPath: projectPath + "ExampleLibrary/ExampleLibrary.xcodeproj", targetName: "ExampleLibraryTests")]))
    }
}
