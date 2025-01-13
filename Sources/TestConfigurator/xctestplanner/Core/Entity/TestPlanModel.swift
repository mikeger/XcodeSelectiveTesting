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
    public var maximumTestExecutionTimeAllowance: Int?
}

// MARK: - CommandLineArgumentEntry

public struct CommandLineArgumentEntry: Codable {
    public let argument: String
    public let enabled: Bool?
}

// MARK: - EnvironmentVariableEntry

public struct EnvironmentVariableEntry: Codable {
    public var key, value: String
    public let enabled: Bool?
}

// MARK: - LocationScenario

public struct LocationScenario: Codable {
    public var identifier: String
}

// MARK: - TestTarget

public struct TestTarget: Codable {
    public var parallelizable: Bool?
    public var skippedTests: Tests?
    public var selectedTests: Tests?
    public var target: Target
    public var enabled: Bool?
}

public enum Tests: Codable {
  case array([String])
  case dictionary(Suites)

  public struct Suites: Codable {
    let suites: [Suite]

    public struct Suite: Codable {
      let name: String
    }
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    if let array = try? container.decode([String].self) {
      self = .array(array)
      return
    }

    if let dict = try? container.decode(Suites.self) {
      self = .dictionary(dict)
      return
    }
    throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid type for skippedTests")
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    switch self {
    case .array(let array):
      try container.encode(array)
    case .dictionary(let dict):
      try container.encode(dict)
    }
  }
}
