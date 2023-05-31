//
//  Created by Mike Gerasymenko <mike@gera.cx>
//

import Foundation

public struct Shell {
    @discardableResult
    public static func exec(_ command: String) throws -> (String, Int32) {
        let task = Process()
        let pipe = Pipe()
        
        task.standardOutput = pipe
        task.arguments = ["-c", command]
        task.executableURL = URL(fileURLWithPath: "/bin/zsh")
        task.standardInput = nil
        
        try task.run()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)!
        
        task.waitUntilExit()
        
        return (output, task.terminationStatus)
    }
    
    @discardableResult
    public static func execOrFail(_ command: String) throws -> String {
        let (result, code) = try exec(command)
        
        if code != 0 {
            throw "Process returned \(code): \(result)"
        }
        
        return result
    }
}
