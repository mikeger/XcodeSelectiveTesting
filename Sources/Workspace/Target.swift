//
//  Created by Mike Gerasymenko <mike@gera.cx>
//

import Foundation
import XcodeProj
import PathKit

public enum TargetIdentity: Hashable {

    case target(projectPath: Path, name: String)
    case swiftPackage(path: Path, name: String)
    
    public init(projectPath: Path, target: PBXNativeTarget) {
        self = .target(projectPath: projectPath, name: target.name)
    }
    
    public init(projectPath: Path, targetName: String) {
        self = .target(projectPath: projectPath, name: targetName)
    }
}

extension TargetIdentity: CustomStringConvertible {
    public var description: String {
        switch self {
        case .target(let projectPath, let name):
            return "Project: \(projectPath), Target: \(name)"
        case .swiftPackage(let path, let name):
            return "Package: \(path), Name: \(name)"
        }
    }
}

extension TargetIdentity {
    public var simpleDescription: String {
        switch self {
        case .target(let projectPath, let name):
            return "\"\(projectPath.lastComponentWithoutExtension):\(name)\""
        case .swiftPackage(let path, let name):
            return "\"\(path.lastComponentWithoutExtension):\(name)\""
        }
    }
}

public struct Target {
    public let identity: TargetIdentity
    public let files: Set<Path>
}
