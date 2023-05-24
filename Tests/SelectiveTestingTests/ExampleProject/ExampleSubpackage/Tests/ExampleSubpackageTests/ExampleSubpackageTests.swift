import XCTest
@testable import ExampleSubpackage

final class ExampleSubpackageTests: XCTestCase {
    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(ExampleSubpackage().text, "Hello, World!")
    }
}
