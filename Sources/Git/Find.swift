//
//  Created by Mike Gerasymenko <mike@gera.cx>
//

import Foundation
import PathKit
import Shell

public struct GitFind {
    public static func repoRoot(at path: Path) throws -> Path {
        let gitPath = try Shell.execOrFail("cd \(path) && git rev-parse --show-toplevel").trimmingCharacters(in: .newlines)

        return Path(gitPath)
    }

    public static func findWithGit(pattern: String, path: Path) throws -> Set<Path> {

        let gitPath = try Shell.execOrFail("cd \(path) && git rev-parse --show-toplevel").trimmingCharacters(in: .newlines)

        let gitRoot = Path(gitPath)

        let result = try Shell.execOrFail("cd \(gitRoot) && git ls-files | grep \(pattern)").trimmingCharacters(in: .newlines)
        
        guard !result.isEmpty else {
            return Set()
        }
        
        return Set(result.components(separatedBy: .newlines).map { gitRoot + $0 } )
    }
}
