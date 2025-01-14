@testable import TestConfigurator
import XCTest

class SkippedTestsTests: XCTestCase {
    // Sample JSON for skippedTests as an array of strings
    let jsonWithArray = """
    {
        "skippedTests": [
            "DigitalRewardsServiceTests",
            "LoyaltyCreditCardRewardsPointViewModelTests"
        ]
    }
    """.data(using: .utf8)!

    // Sample JSON for skippedTests as a dictionary
    let jsonWithDictionary = """
    {
        "skippedTests": {
            "suites": [
                {
                    "name": "SparksMissionOfferVisibleTrackingEventTests"
                }
            ]
        }
    }
    """.data(using: .utf8)!

    func testDecodeSkippedTestsAsArray() throws {
        let decoder = JSONDecoder()
        let container = try decoder.decode(SkippedTestsContainer.self, from: jsonWithArray)

        if case let .array(skippedTests) = container.skippedTests {
            XCTAssertEqual(skippedTests, [
                "DigitalRewardsServiceTests",
                "LoyaltyCreditCardRewardsPointViewModelTests"
            ])
        } else {
            XCTFail("Expected skippedTests to be an array")
        }
    }

    func testDecodeSkippedTestsAsDictionary() throws {
        let decoder = JSONDecoder()
        let container = try decoder.decode(SkippedTestsContainer.self, from: jsonWithDictionary)

        if case let .dictionary(suites) = container.skippedTests {
            XCTAssertEqual(suites.suites.count, 1)
            XCTAssertEqual(suites.suites[0].name, "SparksMissionOfferVisibleTrackingEventTests")
        } else {
            XCTFail("Expected skippedTests to be a dictionary")
        }
    }

    func testEncodeSkippedTestsAsArray() throws {
        let container = SkippedTestsContainer(
            skippedTests: .array([
                "DigitalRewardsServiceTests",
                "LoyaltyCreditCardRewardsPointViewModelTests"
            ])
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let encodedData = try encoder.encode(container)
        let encodedString = String(data: encodedData, encoding: .utf8)

        XCTAssertNotNil(encodedString)
        XCTAssertTrue(encodedString!.contains("\"skippedTests\" : ["))
        XCTAssertTrue(encodedString!.contains("\"DigitalRewardsServiceTests\""))
    }

    func testEncodeSkippedTestsAsDictionary() throws {
        let container = SkippedTestsContainer(
            skippedTests: .dictionary(
                Tests.Suites(suites: [
                    Tests.Suites.Suite(name: "SparksMissionOfferVisibleTrackingEventTests")
                ])
            )
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let encodedData = try encoder.encode(container)
        let encodedString = String(data: encodedData, encoding: .utf8)

        XCTAssertNotNil(encodedString)
        XCTAssertTrue(encodedString!.contains("\"skippedTests\" : {"))
        XCTAssertTrue(encodedString!.contains("\"suites\" : ["))
        XCTAssertTrue(encodedString!.contains("\"name\" : \"SparksMissionOfferVisibleTrackingEventTests\""))
    }
}

// Container to isolate the "skippedTests" field for testing
struct SkippedTestsContainer: Codable {
    let skippedTests: Tests
}
