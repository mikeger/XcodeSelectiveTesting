//
//  Created by Mike Gerasymenko <mike@gera.cx>
//

import Foundation
import PathKit
import XcodeProj

#if compiler(>=6)
extension String: @retroactive Error {}
#else
extension String: Error {}
#endif

extension XCWorkspace {
    public func allProjects(basePath: Path) throws -> [(XcodeProj, Path)] {
        try XCWorkspace.allProjects(from: data.children, basePath: basePath)
    }

    private static func allProjects(from group: [XCWorkspaceDataElement], basePath: Path) throws -> [(XcodeProj, Path)] {
        var projects: [(XcodeProj, Path)] = []

        try group.forEach { element in
            switch element {
            case let .file(file):

                switch file.location {
                case let .absolute(path):
                    guard Path(path).extension == "xcodeproj" else {
                        return
                    }
                    try projects.append((XcodeProj(path: Path(path)), Path(path)))

                case let .group(path):
                    guard Path(path).extension == "xcodeproj" else {
                        return
                    }
                    let resultingPath = basePath + path
                    try projects.append((XcodeProj(path: resultingPath), resultingPath))

                case let .current(path):
                    guard Path(path).extension == "xcodeproj" else {
                        return
                    }
                    let resultingPath = basePath + path
                    try projects.append((XcodeProj(path: resultingPath), resultingPath))

                case let .developer(path):
                    throw "Developer path not supported: \(path)"

                case let .container(path):
                    throw "Container path not supported: \(path)"

                case let .other(_, path):
                    throw "Other path not supported \(path)"
                }

            case let .group(element):
                let groupBasePath = switch element.location {
                case let .absolute(path):
                    Path(path)
                    
                case let .group(path),
                     let .current(path):
                    basePath + path
                
                case .container:
                    basePath
                    
                case let .developer(path):
                    throw "Developer path not supported: \(path)"

                case let .other(_, path):
                    throw "Other path not supported \(path)"
                }
                try projects.append(contentsOf: XCWorkspace.allProjects(from: element.children, basePath: groupBasePath))
            }
        }

        return projects
    }
}
