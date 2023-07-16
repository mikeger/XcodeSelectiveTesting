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
    
    public var path: Path {
        switch self {
        case .swiftPackage(let path, _):
            return path
        case .target(let path, _):
            return path
        }
    }
    
    public var isProject: Bool {
        switch self {
        case .target(_, _):
            return true
        case .swiftPackage(_, _):
            return false
        }
    }
}

extension TargetIdentity: CustomStringConvertible {
    public var description: String {
        switch self {
        case .target(let projectPath, let name):
            return "\"\(projectPath.lastComponentWithoutExtension):\(name)\""
        case .swiftPackage(let packagePath, let name):
            return "\"\(packagePath.lastComponentWithoutExtension):\(name)\""
        }
    }
    
}

extension TargetIdentity {
    
    public var configIdentity: String {
        switch self {
        case .target(let projectPath, let name):
            return "\(projectPath.lastComponentWithoutExtension):\(name)"
        case .swiftPackage(let packagePath, let name):
            return "\(packagePath.lastComponentWithoutExtension):\(name)"
        }
    }
    
}

public struct Target {
    public let identity: TargetIdentity
    public let files: Set<Path>
}
