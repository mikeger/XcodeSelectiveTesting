//
//  Created by Mike Gerasymenko <mike@gera.cx>
//

import Foundation
import PathKit
import Shell

public struct GitFind {

    public static func findWithGit(pattern: String, path: Path) throws -> Set<Path> {

        let gitRoot = try Git.repoRoot(at: path)

        let result = try Shell.execOrFail("cd \(gitRoot) && git ls-files | grep \(pattern)").trimmingCharacters(in: .newlines)
        
        guard !result.isEmpty else {
            return Set()
        }
        
        return Set(result.components(separatedBy: .newlines).map { gitRoot + $0 } )
    }
}
