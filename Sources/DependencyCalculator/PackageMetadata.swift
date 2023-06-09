//
//  Created by Mike Gerasymenko <mike@gera.cx>
//

import Foundation
import PathKit
import Shell
import Workspace

struct PackageMetadata {
    let path: Path
    let name: String
    let dependsOn: Set<TargetIdentity>
    
    static func parse(at path: Path) throws -> PackageMetadata {
        let manifest = try Shell.execOrFail("cd \(path) && swift package dump-package").trimmingCharacters(in: .newlines)
        guard let manifestData = manifest.data(using: .utf8),
              let manifestJson = try JSONSerialization.jsonObject(with: manifestData, options: []) as? [String: Any],
              let name = manifestJson["name"] as? String,
              let dependencies = manifestJson["dependencies"] as? [[String: Any]] else {
            throw "Failed de-serializing the manifest"
        }
        
        var resultDependencies: Set<TargetIdentity> = Set()
        
        dependencies.forEach { dependency in
            guard let fileSystem = dependency["fileSystem"] as? [[String: Any]] else {
                return
            }
            
            fileSystem.forEach { reference in
                guard let pathString = reference["path"] as? String else {
                    return
                }
                let path = Path(pathString)
                // TODO: A shortcut is taken here, where package name is inferred from the path (path.lastComponent)
                resultDependencies.insert(TargetIdentity.swiftPackage(path: path, name: path.lastComponent))
            }
        }
        
        return PackageMetadata(path: path, name: name, dependsOn: resultDependencies)
    }
    
    func targetIdentity() -> TargetIdentity {
        return TargetIdentity.swiftPackage(path: path, name: name)
    }
}
