//
//  Created by Mike Gerasymenko <mike@gera.cx>
//

import XCTest
import PathKit
@testable import SelectiveTesting

final class SelectiveTestingTests: XCTestCase {
    var projectPath: String = ""
    
    override func setUp() async throws {
        try await super.setUp()
        
        let tmpPath = Path.temporary
        guard let exampleInBundle = Bundle(for: SelectiveTestingTests.self).path(forResource: "ExampleProject", ofType: "") else {
            fatalError("Missing ExampleProject in TestBundle")
        }
        try FileManager.default.copyItem(atPath: exampleInBundle, toPath: tmpPath.string)
        
    }
    
    func testExample() throws {
        
    }
}
