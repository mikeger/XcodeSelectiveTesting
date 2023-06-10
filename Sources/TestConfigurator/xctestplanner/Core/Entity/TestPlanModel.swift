import Foundation

// MARK: - Welcome
public struct TestPlanModel: Codable {
    public var configurations: [Configuration]
    public var defaultOptions: DefaultOptions
    public var testTargets: [TestTarget]
    public var version: Int
}

// MARK: - Configuration
public struct Configuration: Codable {
    public var id, name: String
    public var options: Options
}

// MARK: - Options
public struct Options: Codable {
    public var targetForVariableExpansion: Target?
}

// MARK: - Target
public struct Target: Codable {
    public var containerPath, identifier, name: String
}

// MARK: - DefaultOptions
public struct DefaultOptions: Codable {
    public var commandLineArgumentEntries: [CommandLineArgumentEntry]?
    public var environmentVariableEntries: [EnvironmentVariableEntry]?
    public var language: String?
    public var region: String?
    public var locationScenario: LocationScenario?
    public var testTimeoutsEnabled: Bool?
    public var testRepetitionMode: String?
    public var maximumTestRepetitions: Int?
}

// MARK: - CommandLineArgumentEntry
public struct CommandLineArgumentEntry: Codable {
    public let argument: String
    public let enabled: Bool?
}

// MARK: - EnvironmentVariableEntry
public struct EnvironmentVariableEntry: Codable {
    public var key, value: String
}

// MARK: - LocationScenario
public struct LocationScenario: Codable {
    public var identifier: String
}

// MARK: - TestTarget
public struct TestTarget: Codable {
    public var parallelizable: Bool?
    public var skippedTests: [String]?
    public var selectedTests: [String]?
    public var target: Target
}
