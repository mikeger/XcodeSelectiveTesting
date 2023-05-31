//
//  Logger.swift
//  
//
//  Created by Atakan Karslı on 22/12/2022.
//

import Foundation

class Logger {
    enum Level: String {
        case info
        case warning
        case error
    }
    
    static func log(_ message: String, level: Level, withColor: Bool = true) {
        switch level {
        case .info:
            if withColor {
                print("\u{001B}[0;36m[INFO]\u{001B}[0;0m \(message)")
            } else {
                print("[INFO] \(message)")
            }
        case .warning:
            if withColor {
                print("\u{001B}[0;33m[WARNING]\u{001B}[0;0m \(message)")
            } else {
                print("[WARNING] \(message)")
            }
        case .error:
            if withColor {
                print("\u{001B}[0;31m[ERROR]\u{001B}[0;0m \(message)")
            } else {
                print("[ERROR] \(message)")
            }
        }
    }
}
