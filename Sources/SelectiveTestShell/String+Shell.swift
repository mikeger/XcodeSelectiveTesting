//
//  Created by Mike Gerasymenko <mike@gera.cx>
//

import Foundation

public extension String {
    /// Wrap string in single quotes for safe usage in shell commands.
    var shellQuoted: String {
        guard !isEmpty else { return "''" }
        return "'" + self.replacingOccurrences(of: "'", with: "'\"'\"'") + "'"
    }
}
