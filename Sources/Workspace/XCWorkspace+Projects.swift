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
                case .absolute(let path),
                        .group(let path),
                        .current(let path),
                        .developer(let path),
                        .container(let path),
                        .other(_, let path):
                    let resultingPath = basePath + path
                    projects.append((try XcodeProj(path: resultingPath), resultingPath))
                }
                
            case .group(let element):
                projects.append(contentsOf: try XCWorkspace.allProjects(from: element.children, basePath: basePath))
            }
        }
        
        return projects
    }
}
