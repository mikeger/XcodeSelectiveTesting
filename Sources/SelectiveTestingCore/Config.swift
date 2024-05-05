//
//  Created by Mike Gerasymenko <mike@gera.cx>
//

import Foundation
import Workspace
import Yams

struct Config: Codable {
    let basePath: String?
    let testPlan: String?
    let exclude: [String]?

    let extra: WorkspaceInfo.AdditionalConfig?

    static let defaultConfigName = ".xcode-selective-testing.yml"
}

extension Config {
    func save() throws -> String {
        return try YAMLEncoder().encode(self)
    }

    static func load(from data: Data) throws -> Config? {
        return try YAMLDecoder().decode(Self.self, from: data)
    }
}
