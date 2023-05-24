//
//  Created by Mike Gerasymenko <mike@gera.cx>
//

import XCTest
import PathKit
@testable import SelectiveTestingCore
import Shell
import Workspace

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
        try Shell.exec("git config commit.gpgsign false")
        try Shell.exec("git add .")
        try Shell.exec("git commit -m \"Base\"")
        try Shell.exec("git checkout -b feature")
    }
    
    func changeFile(at path: String) throws {
        let handle = FileHandle(forUpdatingAtPath: path)!
        try handle.seekToEnd()
        try handle.write(contentsOf: "\n// change".data(using: .utf8)!)
        try handle.close()
        
        try Shell.exec("git add .")
        try Shell.exec("git commit -m \"Change\"")
    }
    
    func testProjectLoading_empty() async throws {
        // given
        let tool = SelectiveTestingTool(baseBranch: "main",
                                        projectWorkspacePath: projectPath.appending("/ExampleWorkspace.xcworkspace"),
                                        renderDependencyGraph: true)
        // when
        let result = try await tool.run()
        // then
        XCTAssertEqual(result, Set())
    }
    
    func DISABLED_testProjectLoading_changeLibrary() async throws {
        // given
        let tool = SelectiveTestingTool(baseBranch: "main",
                                        projectWorkspacePath: projectPath.appending("/ExampleWorkspace.xcworkspace"),
                                        renderDependencyGraph: true)
        // when
        try changeFile(at: projectPath.appending("/ExampleLibrary/ExampleLibrary/ExampleLibrary.swift"))
        
        // then
        let result = try await tool.run()
        XCTAssertEqual(result, Set([TargetIdentity(projectPath: "ExampleLibrary.xcodeproj", targetName: "ExampleLibrary")]))
    }
}
