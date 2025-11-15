import Foundation

typealias JSONObject = [String: Any]

public struct TestPlanModel {
    private var rawJSON: JSONObject
    public var testTargets: [TestTarget]
    
    public init(data: Data) throws {
        let object = try JSONSerialization.jsonObject(with: data, options: [])
        guard let dictionary = object as? JSONObject else {
            throw TestPlanModelError.invalidFormat
        }
        
        self.rawJSON = dictionary
        self.testTargets = try Self.decodeTargets(from: dictionary["testTargets"])
    }
    
    func encodedData() throws -> Data {
        var json = rawJSON
        json["testTargets"] = try Self.encodeTargets(testTargets)
        return try JSONSerialization.data(withJSONObject: json,
                                          options: [.prettyPrinted, .sortedKeys])
    }
    
    private static func decodeTargets(from value: Any?) throws -> [TestTarget] {
        guard let value, !(value is NSNull) else { return [] }
        guard let array = value as? [Any] else {
            throw TestPlanModelError.invalidTargets
        }
        
        return try array.map { element in
            guard let dictionary = element as? JSONObject else {
                throw TestPlanModelError.invalidTargets
            }
            return try TestTarget(json: dictionary)
        }
    }
    
    private static func encodeTargets(_ targets: [TestTarget]) throws -> [Any] {
        return try targets.map { try $0.encodeJSON() }
    }
}

public enum TestPlanModelError: Error {
    case invalidFormat
    case invalidTargets
    case invalidTargetObject
}

// MARK: - Target

public struct Target {
    private var rawJSON: JSONObject
    public var containerPath: String
    public var identifier: String
    public var name: String
    
    init(json: JSONObject) throws {
        guard let containerPath = json["containerPath"] as? String,
              let identifier = json["identifier"] as? String,
              let name = json["name"] as? String else {
            throw TestPlanModelError.invalidTargetObject
        }
        
        self.rawJSON = json
        self.containerPath = containerPath
        self.identifier = identifier
        self.name = name
    }
    
    func encodeJSON() -> JSONObject {
        var json = rawJSON
        json["containerPath"] = containerPath
        json["identifier"] = identifier
        json["name"] = name
        return json
    }
}

// MARK: - TestTarget

public struct TestTarget {
    private var rawJSON: JSONObject
    public var parallelizable: Bool?
    public var skippedTests: Tests?
    public var selectedTests: Tests?
    public var target: Target
    public var enabled: Bool?
    
    init(json: JSONObject) throws {
        guard let targetJSON = json["target"] as? JSONObject else {
            throw TestPlanModelError.invalidTargetObject
        }
        self.rawJSON = json
        self.parallelizable = json["parallelizable"] as? Bool
        self.enabled = json["enabled"] as? Bool
        self.target = try Target(json: targetJSON)
        self.skippedTests = try Tests.fromJSONValue(json["skippedTests"])
        self.selectedTests = try Tests.fromJSONValue(json["selectedTests"])
    }
    
    func encodeJSON() throws -> JSONObject {
        var json = rawJSON
        json.setJSONValue(parallelizable, forKey: "parallelizable")
        json.setJSONValue(enabled, forKey: "enabled")
        json.setJSONValue(try skippedTests?.jsonValue(), forKey: "skippedTests")
        json.setJSONValue(try selectedTests?.jsonValue(), forKey: "selectedTests")
        json["target"] = target.encodeJSON()
        return json
    }
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

extension Tests {
    static func fromJSONValue(_ value: Any?) throws -> Tests? {
        guard let value, !(value is NSNull) else { return nil }
        let data = try JSONSerialization.data(withJSONObject: value)
        let decoder = JSONDecoder()
        return try decoder.decode(Tests.self, from: data)
    }
    
    func jsonValue() throws -> Any {
        let encoder = JSONEncoder()
        let data = try encoder.encode(self)
        return try JSONSerialization.jsonObject(with: data, options: [])
    }
}

extension Dictionary where Key == String, Value == Any {
    mutating func setJSONValue(_ value: Any?, forKey key: String) {
        if let value {
            self[key] = value
        } else {
            self.removeValue(forKey: key)
        }
    }
}
