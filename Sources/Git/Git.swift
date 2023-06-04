//
//  Created by Mike Gerasymenko <mike@gera.cx>
//

import Foundation
import Shell
import PathKit

public struct Git {
    public static func repoRoot(at path: Path) throws -> Path {
        let gitPath = try Shell.execOrFail("cd \(path) && git rev-parse --show-toplevel").trimmingCharacters(in: .newlines)

        return Path(gitPath).absolute()
    }
}
