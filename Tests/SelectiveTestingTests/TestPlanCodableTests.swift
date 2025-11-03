import Foundation
@testable import TestConfigurator
import Testing

@Suite
struct SkippedTestsTests {
    let jsonWithArray = """
    {
        "skippedTests": [
            "DigitalRewardsServiceTests",
            "LoyaltyCreditCardRewardsPointViewModelTests"
        ]
    }
    """.data(using: .utf8)!

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

    @Test
    func decodeSkippedTestsAsArray() throws {
        let decoder = JSONDecoder()
        let container = try decoder.decode(SkippedTestsContainer.self, from: jsonWithArray)

        if case let .array(skippedTests) = container.skippedTests {
            #expect(skippedTests == [
                "DigitalRewardsServiceTests",
                "LoyaltyCreditCardRewardsPointViewModelTests"
            ])
        } else {
            Issue.record("Expected skippedTests to be an array")
        }
    }

    @Test
    func decodeSkippedTestsAsDictionary() throws {
        let decoder = JSONDecoder()
        let container = try decoder.decode(SkippedTestsContainer.self, from: jsonWithDictionary)

        if case let .dictionary(suites) = container.skippedTests {
            #expect(suites.suites.count == 1)
            #expect(suites.suites[0].name == "SparksMissionOfferVisibleTrackingEventTests")
        } else {
            Issue.record("Expected skippedTests to be a dictionary")
        }
    }

    @Test
    func encodeSkippedTestsAsArray() throws {
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

        #expect(encodedString != nil)
        #expect(encodedString?.contains("\"skippedTests\" : [") == true)
        #expect(encodedString?.contains("\"DigitalRewardsServiceTests\"") == true)
    }

    @Test
    func encodeSkippedTestsAsDictionary() throws {
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

        #expect(encodedString != nil)
        #expect(encodedString?.contains("\"skippedTests\" : {") == true)
        #expect(encodedString?.contains("\"suites\" : [") == true)
        #expect(encodedString?.contains("\"name\" : \"SparksMissionOfferVisibleTrackingEventTests\"") == true)
    }
}

struct SkippedTestsContainer: Codable {
    let skippedTests: Tests
}
