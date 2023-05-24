//
//  Created by Mike Gerasymenko <mike@gera.cx>
//

import Foundation
import PathKit
import Logger
import Shell

extension Path {
    func relative(to rootPath: Path) -> Path {
        return Path(rootPath.url.appendingPathComponent(self.string).path)
    }
}

public struct Changeset {    
    public static func gitChangeset(at path: Path, baseBranch: String) throws -> Set<Path> {
        Logger.message("Finding changeset for repository at \(path)")
        
        let currentBranch = try Shell.exec("cd \(path) && git branch --show-current").trimmingCharacters(in: .newlines)
        Logger.message("Current branch: \(currentBranch)")
        Logger.message("Base branch: \(baseBranch)")
        
        guard !currentBranch.isEmpty else {
            throw ChangesetError.missingCurrentBranch
        }
        
        let changes = try Shell.exec("cd \(path) && git diff \(baseBranch)..\(currentBranch) --name-only")
        let changesTrimmed = changes.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return Set(changesTrimmed.components(separatedBy: .newlines).map { Path($0).relative(to: path) } )
    }
    
    enum ChangesetError: String, Error {
        case missingCurrentBranch = "missingCurrentBranch"
    }
}
