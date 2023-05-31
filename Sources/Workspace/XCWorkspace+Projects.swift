//
//  Created by Mike Gerasymenko <mike@gera.cx>
//

import Foundation
import XcodeProj
import PathKit

extension XCWorkspace {
    public func allProjects(basePath: Path) throws -> [(XcodeProj, Path)] {
        try XCWorkspace.allProjects(from: self.data.children, basePath: basePath)
    }
    
    private static func allProjects(from group: [XCWorkspaceDataElement], basePath: Path) throws -> [(XcodeProj, Path)] {
        var projects: [(XcodeProj, Path)] = []
        
        try group.forEach { element in
            switch element {
            case .file(let file):
                switch file.location {
                case .absolute(let path):
                    projects.append((try XcodeProj(path: Path(path)), Path(path)))

                case .group(let path):
                    let resultingPath = basePath + path
                    projects.append((try XcodeProj(path: resultingPath), resultingPath))

                case .current(let path):
                    let resultingPath = basePath + path
                    projects.append((try XcodeProj(path: resultingPath), resultingPath))

                case .developer(let path):
                    fatalError("Developer path not supported: \(path)")
                    
                case .container(let path):
                    fatalError("Container path not supported: \(path)")

                case .other(_, let path):
                    fatalError("Other path not supported \(path)")

                }
                
            case .group(let element):
                projects.append(contentsOf: try XCWorkspace.allProjects(from: element.children, basePath: basePath))
            }
        }
        
        return projects
    }
}
