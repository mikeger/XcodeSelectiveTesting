//
//  Created by Mike Gerasymenko <mike@gera.cx>
//

import Foundation
import PathKit
import XcodeProj

extension PBXNativeTarget {
    var isTestTarget: Bool {
        switch productType {
        case .unitTestBundle, .uiTestBundle, .ocUnitTestBundle:
            return true
        default:
            return false
        }
    }
}

public struct TargetIdentity: Hashable {
    public enum TargetType {
        case project
        case package
    }

    public let type: TargetType
    public let path: Path
    public let name: String
    public let isTestTarget: Bool

    public static func project(path: Path, target: PBXNativeTarget) -> TargetIdentity {
        TargetIdentity(type: .project, path: path, name: target.name, isTestTarget: target.isTestTarget)
    }

    public static func project(path: Path, targetName: String, testTarget: Bool) -> TargetIdentity {
        TargetIdentity(type: .project, path: path, name: targetName, isTestTarget: testTarget)
    }

    public static func package(path: Path, targetName: String, testTarget: Bool) -> TargetIdentity {
        TargetIdentity(type: .package, path: path, name: targetName, isTestTarget: testTarget)
    }
}

extension TargetIdentity: CustomStringConvertible {
    public var description: String {
        return "\(path.lastComponentWithoutExtension):\(name)"
    }
}

public extension TargetIdentity {
    var configIdentity: String {
        return "\(path.lastComponentWithoutExtension):\(name)"
    }
}

public struct Target {
    public let identity: TargetIdentity
    public let files: Set<Path>
}
