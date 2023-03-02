import Foundation
import XcodeProj
import PathKit

enum TargetIdentity: Hashable {
//    var id: ObjectIdentifier {
//        switch self {
//        case .projectTarget(let projectPath, let name):
//            return ObjectIdentifier("project:\(projectPath) target:\(name)")
//        case .swiftPackage(let path, let name):
//            return ObjectIdentifier("package:\(path) target:\(name)")
//        }
//    }
    
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

struct Target {
    let identity: TargetIdentity
    let files: Set<Path>
}
