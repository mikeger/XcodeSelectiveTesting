import XCTest
@testable import ExamplePackage

final class ExamplePackageTests: XCTestCase {
    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(ExamplePackage().text, "Hello, World!")
    }
}
