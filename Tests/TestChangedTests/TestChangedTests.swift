//
//  Created by Mike Gerasymenko <mike@gera.cx>
//

import XCTest
import PathKit
@testable import TestChanged

final class TestChangedTests: XCTestCase {
    var projectPath: String = ""
    
    override func setUp() async throws {
        try await super.setUp()
        
        let tmpPath = Path.temporary
        guard let exampleInBundle = Bundle(for: TestChangedTests.self).path(forResource: "ExampleProject", ofType: "") else {
            fatalError("Missing ExampleProject in TestBundle")
        }
        try FileManager.default.copyItem(atPath: exampleInBundle, toPath: tmpPath.string)
        
    }
    
    func testExample() throws {
        
    }
}
