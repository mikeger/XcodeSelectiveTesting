//
//  TestPlanHelper.swift
//
//
//  Created by Atakan Karslı on 20/12/2022.
//

import Foundation
import Logging

let logger = Logger(label: "cx.gera.XcodeSelectiveTesting")

public class TestPlanHelper {
    public static func readTestPlan(filePath: String) throws -> TestPlanModel {
        logger.info("Reading test plan from file: \(filePath)")
        let url = URL(fileURLWithPath: filePath)
        let data = try Data(contentsOf: url)
        return try TestPlanModel(data: data)
    }

    static func writeTestPlan(_ testPlan: TestPlanModel, filePath: String) throws {
        logger.info("Writing updated test plan to file: \(filePath)")
        let updatedData = try testPlan.encodedData()
        let url = URL(fileURLWithPath: filePath)
        try updatedData.write(to: url)
    }

    static func checkForTestTargets(testPlan: TestPlanModel) {
        if testPlan.testTargets.isEmpty {
            logger.error("Test plan does not have any test targets. Add a test target before attempting to update the selected or skipped tests.")
            exit(1)
        }
    }
}
