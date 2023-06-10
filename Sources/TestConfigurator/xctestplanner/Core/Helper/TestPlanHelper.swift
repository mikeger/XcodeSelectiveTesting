//
//  TestPlanHelper.swift
//  
//
//  Created by Atakan Karslı on 20/12/2022.
//

import ArgumentParser
import Foundation
import Logger

public class TestPlanHelper {
    public static func readTestPlan(filePath: String) throws -> TestPlanModel {
        Logger.message("Reading test plan from file: \(filePath)")
        let url = URL(fileURLWithPath: filePath)
        let data = try Data(contentsOf: url)
        
        let decoder = JSONDecoder()
        return try decoder.decode(TestPlanModel.self, from: data)
    }
    
    static func writeTestPlan(_ testPlan: TestPlanModel, filePath: String) throws {
        Logger.message("Writing updated test plan to file: \(filePath)")
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let updatedData = try encoder.encode(testPlan)
        
        let url = URL(fileURLWithPath: filePath)
        try updatedData.write(to: url)
    }
    
    static func updateSkippedTests(testPlan: inout TestPlanModel, tests: [String], override: Bool) {
        checkForTestTargets(testPlan: testPlan)
        for (index, _) in testPlan.testTargets.enumerated() {
            if testPlan.testTargets[index].selectedTests != nil {
                testPlan.testTargets[index].selectedTests = nil
            }
            if override {
                Logger.message("Overriding skipped tests in test plan")
                testPlan.testTargets[index].skippedTests = tests
            } else {
                if testPlan.testTargets[index].skippedTests == nil {
                    testPlan.testTargets[index].skippedTests = []
                }
                Logger.message("Append given tests to skipped tests in test plan")
                testPlan.testTargets[index].skippedTests?.append(contentsOf: tests)
            }
        }
    }
    
    static func updateSelectedTests(testPlan: inout TestPlanModel, with tests: [String], override: Bool) {
        checkForTestTargets(testPlan: testPlan)
        for (index, _) in testPlan.testTargets.enumerated() {
            if testPlan.testTargets[index].skippedTests != nil {
                testPlan.testTargets[index].skippedTests = nil
            }
            if override {
                Logger.message("Overriding selected tests in test plan")
                testPlan.testTargets[index].selectedTests = tests
            } else {
                if testPlan.testTargets[index].selectedTests == nil {
                    testPlan.testTargets[index].selectedTests = []
                }
                Logger.message("Append given tests to selected tests in test plan")
                testPlan.testTargets[index].selectedTests?.append(contentsOf: tests)
            }
        }
    }
    
    static func removeTests(testPlan: inout TestPlanModel, with tests: [String]) {
        checkForTestTargets(testPlan: testPlan)
        for (index, _) in testPlan.testTargets.enumerated() {
            Logger.message("Remove given tests from selected tests in test plan")
            for test in tests {
                testPlan.testTargets[index].selectedTests?.remove(object: test)
            }
        }
    }
    
    static func updateRerunCount(testPlan: inout TestPlanModel, to count: Int) {
        Logger.message("Updating rerun count in test plan to: \(count)")
        if testPlan.defaultOptions.testRepetitionMode == nil {
            testPlan.defaultOptions.testRepetitionMode = TestPlanValue.retryOnFailure.rawValue
        }
        testPlan.defaultOptions.maximumTestRepetitions = count
    }
    
    static func updateLanguage(testPlan: inout TestPlanModel, to language: String) {
        Logger.message("Updating language in test plan to: \(language)")
        testPlan.defaultOptions.language = language.lowercased()
    }
    
    static func updateRegion(testPlan: inout TestPlanModel, to region: String) {
        Logger.message("Updating region in test plan to: \(region)")
        testPlan.defaultOptions.region = region.uppercased()
    }
    
    static func setEnvironmentVariable(testPlan: inout TestPlanModel, key: String, value: String) {
        Logger.message("Setting environment variable with key '\(key)' and value '\(value)' in test plan")
        if testPlan.defaultOptions.environmentVariableEntries == nil {
            testPlan.defaultOptions.environmentVariableEntries = []
        }
        testPlan.defaultOptions.environmentVariableEntries?.append(EnvironmentVariableEntry(key: key, value: value))
    }
    
    static func setArgument(testPlan: inout TestPlanModel, key: String, disabled: Bool) {
        if testPlan.defaultOptions.commandLineArgumentEntries == nil {
            testPlan.defaultOptions.commandLineArgumentEntries = []
        }
        if disabled {
            Logger.message("Setting command line argument with key '\(key)' in test plan as disabled")
            testPlan.defaultOptions.commandLineArgumentEntries?.append(CommandLineArgumentEntry(argument: key, enabled: !disabled))
        } else {
            Logger.message("Setting command line argument with key '\(key)', enabled by default")
            testPlan.defaultOptions.commandLineArgumentEntries?.append(CommandLineArgumentEntry(argument: key, enabled: nil))
        }
    }
    
    static func checkForTestTargets(testPlan: TestPlanModel) {
        if testPlan.testTargets.isEmpty {
            Logger.error("Test plan does not have any test targets. Add a test target before attempting to update the selected or skipped tests.")
            exit(1)
        }
    }
}

enum TestPlanValue: String {
    case retryOnFailure
}
