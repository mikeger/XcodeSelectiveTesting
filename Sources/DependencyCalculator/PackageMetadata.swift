//
//  Created by Mike Gerasymenko <mike@gera.cx>
//

import Foundation
import PathKit
import SelectiveTestShell
import Workspace
import SelectiveTestLogger

struct PackageTargetMetadata {
    let path: Path
    let affectedBy: Set<Path>
    let name: String
    let dependsOn: Set<TargetIdentity>
    
    // TODO: Split in several methods
    static func parse(at path: Path) throws -> [PackageTargetMetadata] {
        // NB: Flag `--disable-sandbox` is required to allow running SPM from an SPM plugin
        let manifest = try Shell.execOrFail("cd \(path) && swift package dump-package --disable-sandbox").trimmingCharacters(in: .newlines)
        guard let manifestData = manifest.data(using: .utf8),
              let manifestJson = try JSONSerialization.jsonObject(with: manifestData, options: []) as? [String: Any],
              let targets = manifestJson["targets"] as? [[String: Any]]
        else {
            throw "Failed de-serializing the manifest"
        }
        
        var filesystemDeps: [String: Path] = [:]
        
        (manifestJson["dependencies"] as? [[String: Any]])?.forEach { dependency in
            // We only include filesystem dependencies
            guard let fileSystem = dependency["fileSystem"] as? [[String: Any]] else {
                return
            }

            fileSystem.forEach { reference in
                guard let pathString = reference["path"] as? String,
                      let identity = reference["identity"] as? String else {
                    return
                }
                let path = Path(pathString).absolute()
                filesystemDeps[identity] = path
            }
        }
        
        return targets.compactMap { target -> PackageTargetMetadata? in
            
            guard let targetName = target["name"] as? String else {
                return nil
            }
            
            let dependencies: [TargetIdentity]
            
            if let dependenciesDescriptions = target["dependencies"] as? [[String: Any]] {
                dependencies = dependenciesDescriptions.compactMap { dependencyDescription -> TargetIdentity? in
                    if let product = dependencyDescription["product"] as? [Any],
                       let depTarget = product[0] as? String,
                       let depPackageName = product[1] as? String,
                       let depPath = filesystemDeps[depPackageName.lowercased()] {
                        
                        return TargetIdentity.swiftPackage(path: depPath, name: depTarget)
                    }
                    else if let byName = dependencyDescription["byName"] as? [Any],
                            let depName = byName[0] as? String {
                        if let depPath = filesystemDeps[depName.lowercased()] {
                            return TargetIdentity.swiftPackage(path: depPath, name: depName)
                        }
                        else {
                            return TargetIdentity.swiftPackage(path: path, name: depName)
                        }
                    }
                    else {
                        return nil
                    }
                }
            }
            else {
                dependencies = []
            }
            
            let type = target["type"] as? String
            
            var affectedBy = Set<Path>([path + "Package.swift"])
            
            let typePath: String
            
            if type == "test" {
                typePath = "Tests"
            }
            else {
                typePath = "Sources"
            }
            
            let specificPath = target["path"] != nil
            let targetRootPath: Path
            if let specificPath = target["path"] as? String {
                targetRootPath = path + specificPath
            }
            else {
                targetRootPath = path + typePath
            }
            
            
            if let resources = target["resources"] as? [[String: Any]] {
                resources.forEach { resource in
                    if let resourcePath = resource["path"] as? String {
                        affectedBy.insert(targetRootPath + resourcePath)
                    }
                }
            }
            if let sources = target["sources"] as? [String] {
                sources.forEach { source in
                    affectedBy.insert(targetRootPath + source)
                }
            }
            else {
                if specificPath {
                    affectedBy.insert(targetRootPath)
                }
                else {
                    affectedBy.insert(targetRootPath + targetName)
                }
            }
            
            return PackageTargetMetadata(path: path,
                                         affectedBy: affectedBy,
                                         name: targetName,
                                         dependsOn: Set(dependencies))
        }
    }
    
    func targetIdentity() -> TargetIdentity {
        return TargetIdentity.swiftPackage(path: path, name: name)
    }
}
