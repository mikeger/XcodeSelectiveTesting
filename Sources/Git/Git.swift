//
//  Created by Mike Gerasymenko <mike@gera.cx>
//

import Foundation
import PathKit
import SelectiveTestShell

public struct Git {
    let path: Path

    public init(path: Path) {
        self.path = path
    }

    public func repoRoot() throws -> Path {
        let gitPath = try Shell.execOrFail("(cd \"\(path)\" && git rev-parse --show-toplevel)").trimmingCharacters(in: .newlines)

        return Path(gitPath).absolute()
    }

    public func find(pattern: String) throws -> Set<Path> {
        let gitRoot = try repoRoot()

        let result = try Shell.exec("(cd \"\(gitRoot)\" && git ls-files | grep \(pattern))").0.trimmingCharacters(in: .newlines)

        guard !result.isEmpty else {
            return Set()
        }

        return Set(result.components(separatedBy: .newlines).map { gitRoot + $0 })
    }
}
