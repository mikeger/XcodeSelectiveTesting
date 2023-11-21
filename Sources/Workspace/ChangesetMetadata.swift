//
//  Created by Mike Gerasymenko <mike@gera.cx>
//

import Foundation
import PathKit

public struct ChangesetMetadata: Hashable {
    public let path: Path
    public let changedLines: Int
    
    static let regex = try! NSRegularExpression(pattern: "^(.*)\\|\\s*(\\d*)")
    
    init(path: Path, changedLines: Int) {
        self.path = path
        self.changedLines = changedLines
    }
    
    public init?(gitStatOutput: String) {
        // Output example
        // Tests/SelectiveTestingTests/IntegrationTestTool.swift           | 28 ++++++++++++++--------------
        
        guard let result = ChangesetMetadata.regex.firstMatch(in: gitStatOutput,
                                                              range: NSRange(location: 0, length: gitStatOutput.count)) else {
            return nil
        }
        
        let filenameRange = result.range(at: 1)
        let lineChangeRange = result.range(at: 2)
        
        guard filenameRange.location != NSNotFound,
                lineChangeRange.location != NSNotFound,
              let filenameSwiftRange = Range(filenameRange, in: gitStatOutput),
              let lineSwiftRange = Range(lineChangeRange, in: gitStatOutput)
        else {
            return nil
        }
        
        let filename = gitStatOutput[filenameSwiftRange]
        let lineChange = gitStatOutput[lineSwiftRange]
        
        path = Path(filename.trimmingCharacters(in: .whitespacesAndNewlines))
        changedLines = Int(lineChange.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
    }
}
