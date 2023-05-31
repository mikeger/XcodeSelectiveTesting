//
//  Created by Mike Gerasymenko <mike@gera.cx>
//

import Foundation
import PathKit
import Logger
import Shell

public struct Changeset {    
    public static func gitChangeset(at path: Path, baseBranch: String) throws -> Set<Path> {
        Logger.message("Finding changeset for repository at \(path)")
        
        let currentBranch = try Shell.execOrFail("cd \(path) && git branch --show-current").trimmingCharacters(in: .newlines)
        Logger.message("Current branch: \(currentBranch)")
        Logger.message("Base branch: \(baseBranch)")
        
        guard !currentBranch.isEmpty else {
            throw ChangesetError.missingCurrentBranch
        }
        
        let changes = try Shell.execOrFail("cd \(path) && git diff \(baseBranch)..\(currentBranch) --name-only")
        let changesTrimmed = changes.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !changesTrimmed.isEmpty else {
            return Set()
        }
        
        return Set(changesTrimmed.components(separatedBy: .newlines).map { path + $0 } )
    }
    
    enum ChangesetError: String, Error {
        case missingCurrentBranch = "missingCurrentBranch"
    }
}
