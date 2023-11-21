//
//  Created by Mike Gerasymenko <mike@gera.cx>
//

import Foundation
import PathKit
import SelectiveTestLogger
import SelectiveTestShell
import Workspace

extension Git {
    public func changeset(baseBranch: String, verbose: Bool = false) throws -> Set<ChangesetMetadata> {
        let gitRoot = try repoRoot()
        
        var currentBranch = try Shell.execOrFail("cd \(gitRoot) && git branch --show-current").trimmingCharacters(in: .newlines)
        if verbose {
            Logger.message("Current branch: \(currentBranch)")
            Logger.message("Base branch: \(baseBranch)")
        }
        
        if currentBranch.isEmpty {
            Logger.warning("Missing current branch at \(path)")
            
            currentBranch = "HEAD"
        }
        
        let changes = try Shell.execOrFail("cd \(path) && git diff \(baseBranch)..\(currentBranch) --stat")
        let changesTrimmed = changes.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !changesTrimmed.isEmpty else {
            return Set()
        }
        
        return Set(changesTrimmed.components(separatedBy: .newlines).compactMap { line in
            ChangesetMetadata(gitStatOutput: line)
        })
    }
    
    public func localChangeset() throws -> Set<ChangesetMetadata> {
        let gitRoot = try repoRoot()
        
        let changes = try Shell.execOrFail("cd \(gitRoot) && git diff --stat")
        let changesTrimmed = changes.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !changesTrimmed.isEmpty else {
            return Set()
        }
        
        return Set(changesTrimmed.components(separatedBy: .newlines).compactMap { line in
            ChangesetMetadata(gitStatOutput: line)
        })
    }
}
