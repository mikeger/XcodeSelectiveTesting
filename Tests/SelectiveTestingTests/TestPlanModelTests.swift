import Foundation
import PathKit
@testable import TestConfigurator
import Testing
import Workspace

@Suite
struct TestPlanModelTests {
    private let samplePlanData = """
    {
      "configurations": [],
      "defaultOptions": {
        "language": "en"
      },
      "futureTopLevel": {
        "flag": true
      },
      "testTargets": [
        {
          "parallelizable": true,
          "customField": "keepMe",
          "target": {
            "containerPath": "container",
            "identifier": "com.example.tests",
            "name": "ExampleTests",
            "newTargetMetadata": {
              "foo": "bar"
            }
          }
        }
      ],
      "version": 1
    }
    """.data(using: .utf8)!

    @Test
    func preservesUnknownKeysWhenUpdatingPlan() throws {
        var plan = try TestPlanModel(data: samplePlanData)
        let identity = TargetIdentity.project(path: Path("/tmp/Example.xcodeproj"),
                                              targetName: "ExampleTests",
                                              testTarget: true)

        TestPlanHelper.updateSelectedTestTargets(testPlan: &plan, with: [identity])

        let encoded = try plan.encodedData()
        guard let json = try JSONSerialization.jsonObject(with: encoded) as? [String: Any],
              let futureTopLevel = json["futureTopLevel"] as? [String: Bool],
              let testTargets = json["testTargets"] as? [Any],
              let firstTarget = testTargets.first as? [String: Any],
              let nestedTarget = firstTarget["target"] as? [String: Any],
              let metadata = nestedTarget["newTargetMetadata"] as? [String: String]
        else {
            Issue.record("Failed to decode encoded test plan JSON")
            return
        }

        #expect(futureTopLevel["flag"] == true)
        #expect(firstTarget["customField"] as? String == "keepMe")
        #expect(metadata["foo"] == "bar")
        #expect(firstTarget["enabled"] as? Bool == true)
    }

    @Test
    func targetPreservesUnknownKeysWhenMutated() throws {
        var plan = try TestPlanModel(data: samplePlanData)
        guard var testTarget = plan.testTargets.first else {
            Issue.record("Missing test target")
            return
        }

        testTarget.target.identifier = "com.example.updated"
        testTarget.target.name = "RenamedTests"
        plan.testTargets = [testTarget]

        let encoded = try plan.encodedData()
        guard let json = try JSONSerialization.jsonObject(with: encoded) as? [String: Any],
              let testTargets = json["testTargets"] as? [Any],
              let firstTarget = testTargets.first as? [String: Any],
              let nestedTarget = firstTarget["target"] as? [String: Any],
              let metadata = nestedTarget["newTargetMetadata"] as? [String: String]
        else {
            Issue.record("Failed to decode encoded test plan JSON")
            return
        }

        #expect(nestedTarget["identifier"] as? String == "com.example.updated")
        #expect(nestedTarget["name"] as? String == "RenamedTests")
        #expect(metadata["foo"] == "bar")
    }
}
