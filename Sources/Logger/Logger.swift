//
//  Created by Mike Gerasymenko <mike@gera.cx>
//

import Foundation
import Rainbow

public struct Logger {
    public static func message(_ message: String) {
        print(message)
    }
    
    public static func warning(_ message: String) {
        print("[WARN]: \(message.yellow)")
    }
    
    public static func error(_ message: String) {
        print("[ERROR]: \(message.red)")
    }
}
