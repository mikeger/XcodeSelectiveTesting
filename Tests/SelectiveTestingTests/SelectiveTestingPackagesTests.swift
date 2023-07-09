//
//  Created by Mike Gerasymenko <mike@gera.cx>
//

import XCTest
import PathKit
@testable import SelectiveTestingCore
import Shell
import Workspace

final class SelectiveTestingPackagesTests: XCTestCase {
    
    let testTool = IntegrationTestTool()
    
    override func setUp() async throws {
        try await super.setUp()
        
        try testTool.setUp()
    }
    
    override func tearDown() async throws {
        try await super.tearDown()
        
        try testTool.tearDown()
    }
    
    func testProjectLoading_changePackage() async throws {
        // given
        let tool = try testTool.createSUT()
        // when
        try testTool.changeFile(at: testTool.projectPath + "ExamplePackage/Sources/ExamplePackage/ExamplePackage.swift")
        
        // then
        let result = try await tool.run()
        XCTAssertEqual(result, Set([testTool.mainProjectMainTarget,
                                    testTool.mainProjectTests,
                                    testTool.mainProjectUITests,
                                    testTool.package,
                                    testTool.packageTests]))
    }
    
    func testProjectLoading_changePackageDefintion() async throws {
        // given
        let tool = try testTool.createSUT()
        // when
        try testTool.changeFile(at: testTool.projectPath + "ExamplePackage/Package.swift")
        
        // then
        let result = try await tool.run()
        XCTAssertEqual(result, Set([testTool.mainProjectMainTarget,
                                    testTool.mainProjectTests,
                                    testTool.mainProjectUITests,
                                    testTool.package,
                                    testTool.packageTests]))
    }
    
    func testProjectLoading_packageAddFile() async throws {
        // given
        let tool = try testTool.createSUT()
        // when
        try testTool.addFile(at: testTool.projectPath + "ExamplePackage/Sources/ExamplePackage/ExamplePackageFile.swift")
        
        // then
        let result = try await tool.run()
        XCTAssertEqual(result, Set([testTool.mainProjectMainTarget,
                                    testTool.mainProjectTests,
                                    testTool.mainProjectUITests,
                                    testTool.package,
                                    testTool.packageTests]))
    }
    
    func testProjectLoading_packageRemoveFile() async throws {
        // given
        let tool = try testTool.createSUT()
        // when
        try testTool.removeFile(at: testTool.projectPath + "ExamplePackage/Sources/ExamplePackage/ExamplePackage.swift")
        
        // then
        let result = try await tool.run()
        XCTAssertEqual(result, Set([testTool.mainProjectMainTarget,
                                    testTool.mainProjectTests,
                                    testTool.mainProjectUITests,
                                    testTool.package,
                                    testTool.packageTests]))
    }
}
