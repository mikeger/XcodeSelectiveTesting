import Foundation
import XcodeProj
import PathKit

enum TargetIdentity: Hashable {

    case projectTarget(projectPath: Path, name: String)
    case swiftPackage(path: Path, name: String)
    
    init(projectPath: Path, target: PBXNativeTarget) {
        self = .projectTarget(projectPath: projectPath, name: target.name)
    }
    
    init(projectPath: Path, targetName: String) {
        self = .projectTarget(projectPath: projectPath, name: targetName)
    }
}

extension TargetIdentity: CustomStringConvertible {
    var description: String {
        switch self {
        case .projectTarget(let projectPath, let name):
            return "Project: \(projectPath), Target: \(name)"
        case .swiftPackage(let path, let name):
            return "Swift Package: \(path), Name: \(name)"
        }
    }
}

extension TargetIdentity {
    var simpleDescription: String {
        switch self {
        case .projectTarget(let projectPath, let name):
            return "\"\(projectPath.lastComponentWithoutExtension):\(name)\""
        case .swiftPackage(let path, let name):
            return "\"\(path.lastComponentWithoutExtension):\(name)\""
        }
    }
}

struct Target {
    let identity: TargetIdentity
    let files: Set<Path>
}
