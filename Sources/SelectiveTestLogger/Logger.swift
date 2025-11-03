//
//  Created by Mike Gerasymenko <mike@gera.cx>
//

import Foundation
import Rainbow

public struct StandardErrorOutputStream: TextOutputStream {
    public mutating func write(_ string: String) { fputs(string, stderr) }
}

public enum Logger {
    private static func write(_ message: String) {
        var stream = StandardErrorOutputStream()
        print(message, to: &stream)
    }

    public static func message(_ message: String) {
        write(message)
    }

    public static func warning(_ message: String) {
        write("[WARN]: \(message)".yellow)
    }

    public static func error(_ message: String) {
        write("[ERROR]: \(message)".red)
    }
}
