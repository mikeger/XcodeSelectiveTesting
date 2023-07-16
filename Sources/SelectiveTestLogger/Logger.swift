//
//  Created by Mike Gerasymenko <mike@gera.cx>
//

import Foundation
import Rainbow

public struct StandardErrorOutputStream: TextOutputStream {
    public mutating func write(_ string: String) { fputs(string, stderr) }
}

public var errStream = StandardErrorOutputStream()

public struct Logger {
    public static func message(_ message: String) {
        print(message, to: &errStream)
    }
    
    public static func warning(_ message: String) {
        print("[WARN]: \(message)".yellow, to: &errStream)
    }
    
    public static func error(_ message: String) {
        print("[ERROR]: \(message)".red, to: &errStream)
    }
}
