//
//  Created by Mike Gerasymenko <mike@gera.cx>
//

import Foundation
import Yams
import Workspace

struct Config: Codable {
    let projectOrWorkspace: String?
    let testPlan: String?
    
    let extra: WorkspaceInfo.AdditionalConfig?
    
    static let defaultConfigName = ".selective-testing.yml"
}

extension Config {
    func save() throws -> String {
        return try YAMLEncoder().encode(self)
    }
    
    static func load(from data: Data) throws -> Config? {
        return try YAMLDecoder().decode(Self.self, from: data)
    }
}
