//
//  TestPlanHelper.swift
//  
//
//  Created by Atakan Karslı on 20/12/2022.
//

import ArgumentParser
import Foundation

class TestPlanHelper {
    static func readTestPlan(filePath: String) throws -> TestPlanModel {
        Logger.log("Reading test plan from file: \(filePath)", level: .info)
        let url = URL(fileURLWithPath: filePath)
        let data = try Data(contentsOf: url)
        
        let decoder = JSONDecoder()
        return try decoder.decode(TestPlanModel.self, from: data)
    }
    
    static func writeTestPlan(_ testPlan: TestPlanModel, filePath: String) throws {
        Logger.log("Writing updated test plan to file: \(filePath)", level: .info)
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
                Logger.log("Overriding skipped tests in test plan", level: .warning)
                testPlan.testTargets[index].skippedTests = tests
            } else {
                if testPlan.testTargets[index].skippedTests == nil {
                    testPlan.testTargets[index].skippedTests = []
                }
                Logger.log("Append given tests to skipped tests in test plan", level: .info)
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
                Logger.log("Overriding selected tests in test plan", level: .warning)
                testPlan.testTargets[index].selectedTests = tests
            } else {
                if testPlan.testTargets[index].selectedTests == nil {
                    testPlan.testTargets[index].selectedTests = []
                }
                Logger.log("Append given tests to selected tests in test plan", level: .info)
                testPlan.testTargets[index].selectedTests?.append(contentsOf: tests)
            }
        }
    }
    
    static func removeTests(testPlan: inout TestPlanModel, with tests: [String]) {
        checkForTestTargets(testPlan: testPlan)
        for (index, _) in testPlan.testTargets.enumerated() {
            Logger.log("Remove given tests from selected tests in test plan", level: .info)
            for test in tests {
                testPlan.testTargets[index].selectedTests?.remove(object: test)
            }
        }
    }
    
    static func updateRerunCount(testPlan: inout TestPlanModel, to count: Int) {
        Logger.log("Updating rerun count in test plan to: \(count)", level: .info)
        if testPlan.defaultOptions.testRepetitionMode == nil {
            testPlan.defaultOptions.testRepetitionMode = TestPlanValue.retryOnFailure.rawValue
        }
        testPlan.defaultOptions.maximumTestRepetitions = count
    }
    
    static func updateLanguage(testPlan: inout TestPlanModel, to language: String) {
        Logger.log("Updating language in test plan to: \(language)", level: .info)
        testPlan.defaultOptions.language = language.lowercased()
    }
    
    static func updateRegion(testPlan: inout TestPlanModel, to region: String) {
        Logger.log("Updating region in test plan to: \(region)", level: .info)
        testPlan.defaultOptions.region = region.uppercased()
    }
    
    static func setEnvironmentVariable(testPlan: inout TestPlanModel, key: String, value: String) {
        Logger.log("Setting environment variable with key '\(key)' and value '\(value)' in test plan", level: .info)
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
            Logger.log("Setting command line argument with key '\(key)' in test plan as disabled", level: .info)
            testPlan.defaultOptions.commandLineArgumentEntries?.append(CommandLineArgumentEntry(argument: key, enabled: !disabled))
        } else {
            Logger.log("Setting command line argument with key '\(key)', enabled by default", level: .info)
            testPlan.defaultOptions.commandLineArgumentEntries?.append(CommandLineArgumentEntry(argument: key, enabled: nil))
        }
    }
    
    static func checkForTestTargets(testPlan: TestPlanModel) {
        if testPlan.testTargets.isEmpty {
            Logger.log("Error: Test plan does not have any test targets. Add a test target before attempting to update the selected or skipped tests.", level: .error)
            exit(1)
        }
    }
}

enum TestPlanValue: String {
    case retryOnFailure
}
