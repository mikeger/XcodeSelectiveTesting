import Foundation

// MARK: - Welcome
struct TestPlanModel: Codable {
    var configurations: [Configuration]
    var defaultOptions: DefaultOptions
    var testTargets: [TestTarget]
    var version: Int
}

// MARK: - Configuration
struct Configuration: Codable {
    var id, name: String
    var options: Options
}

// MARK: - Options
struct Options: Codable {
    var targetForVariableExpansion: Target?
}

// MARK: - Target
struct Target: Codable {
    var containerPath, identifier, name: String
}

// MARK: - DefaultOptions
struct DefaultOptions: Codable {
    var commandLineArgumentEntries: [CommandLineArgumentEntry]?
    var environmentVariableEntries: [EnvironmentVariableEntry]?
    var language: String?
    var region: String?
    var locationScenario: LocationScenario?
    var testTimeoutsEnabled: Bool?
    var testRepetitionMode: String?
    var maximumTestRepetitions: Int?
}

// MARK: - CommandLineArgumentEntry
struct CommandLineArgumentEntry: Codable {
    let argument: String
    let enabled: Bool?
}

// MARK: - EnvironmentVariableEntry
struct EnvironmentVariableEntry: Codable {
    var key, value: String
}

// MARK: - LocationScenario
struct LocationScenario: Codable {
    var identifier: String
}

// MARK: - TestTarget
struct TestTarget: Codable {
    var parallelizable: Bool?
    var skippedTests: [String]?
    var selectedTests: [String]?
    var target: Target
}
