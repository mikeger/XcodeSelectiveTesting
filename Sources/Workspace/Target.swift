//
//  Created by Mike Gerasymenko <mike@gera.cx>
//

import Foundation
import XcodeProj
import PathKit

extension PBXNativeTarget {
    var isTestTarget: Bool {
        switch self.productType {
        case .unitTestBundle, .uiTestBundle, .ocUnitTestBundle:
            return true
        default:
            return false
        }
    }
}

public enum TargetIdentity: Hashable {
    
    case project(projectPath: Path, name: String, testTarget: Bool)
    case package(path: Path, name: String, testTarget: Bool)
    
    public init(projectPath: Path, target: PBXNativeTarget) {
        self = .project(projectPath: projectPath, name: target.name, testTarget: target.isTestTarget)
    }
    
    public init(projectPath: Path, targetName: String, testTarget: Bool) {
        self = .project(projectPath: projectPath, name: targetName, testTarget: testTarget)
    }
    
    public var path: Path {
        switch self {
        case .package(let path, _, _):
            return path
        case .project(let path, _, _):
            return path
        }
    }
    
    public var isProject: Bool {
        switch self {
        case .project(_, _, _):
            return true
        case .package(_, _, _):
            return false
        }
    }
    
    public var isTestTarget: Bool {
        switch self {
        case .project(_, _, let test):
            return test
        case .package(_, _, let test):
            return test
        }
    }
}

extension TargetIdentity: CustomStringConvertible {
    public var description: String {
        switch self {
        case .project(let projectPath, let name, _):
            return "\(projectPath.lastComponentWithoutExtension):\(name)"
        case .package(let packagePath, let name, _):
            return "\(packagePath.lastComponentWithoutExtension):\(name)"
        }
    }
    
}

extension TargetIdentity {
    
    public var configIdentity: String {
        switch self {
        case .project(let projectPath, let name, _):
            return "\(projectPath.lastComponentWithoutExtension):\(name)"
        case .package(let packagePath, let name, _):
            return "\(packagePath.lastComponentWithoutExtension):\(name)"
        }
    }
    
}

public struct Target {
    public let identity: TargetIdentity
    public let files: Set<Path>
}
