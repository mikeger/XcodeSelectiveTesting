//
//  Created by Mike Gerasymenko <mike@gera.cx>
//

import Foundation
import PathKit
import SelectiveTestLogger
import SelectiveTestShell
import Workspace

struct PackageTargetMetadata {
    let path: Path
    let affectedBy: Set<Path>
    let name: String
    let dependsOn: Set<TargetIdentity>
    let testTarget: Bool

    // TODO: Split in several methods
    static func parse(at path: Path) throws -> [PackageTargetMetadata] {
        // NB:
        //  - Flag `--disable-sandbox` is required to allow running SPM from an SPM plugin
        //  - Flag `--ignore-lock` is required to avoid locking the package build directory when exectuting from SPM plugin (Swift 6).
        var flags = ["--disable-sandbox"]
        if try isSwiftVersion6Plus() {
            flags.append("--ignore-lock")
        }

        let manifest = try Shell.execOrFail("cd \(path) && swift package dump-package \(flags.joined(separator: " "))")
            .trimmingCharacters(in: .newlines)
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

            for reference in fileSystem {
                guard let pathString = reference["path"] as? String,
                      let identity = reference["identity"] as? String
                else {
                    continue
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
                       let depPath = filesystemDeps[depPackageName.lowercased()]
                    {
                        return TargetIdentity.package(path: depPath, targetName: depTarget, testTarget: false)
                    } else if let byName = dependencyDescription["byName"] as? [Any],
                              let depName = byName[0] as? String
                    {
                        if let depPath = filesystemDeps[depName.lowercased()] {
                            return TargetIdentity.package(path: depPath, targetName: depName, testTarget: false)
                        } else {
                            return TargetIdentity.package(path: path, targetName: depName, testTarget: false)
                        }
                    } else {
                        return nil
                    }
                }
            } else {
                dependencies = []
            }

            let type = target["type"] as? String

            var affectedBy = Set<Path>([path + "Package.swift"])

            let typePath: String

            if type == "test" {
                typePath = "Tests"
            } else {
                typePath = "Sources"
            }

            let specificPath = target["path"] != nil
            let targetRootPath: Path
            if let specificPath = target["path"] as? String {
                targetRootPath = path + specificPath
            } else {
                targetRootPath = path + typePath
            }

            if let resources = target["resources"] as? [[String: Any]] {
                for resource in resources {
                    if let resourcePath = resource["path"] as? String {
                        affectedBy.insert(targetRootPath + targetName + resourcePath)
                    }
                }
            }
            if let sources = target["sources"] as? [String] {
                for source in sources {
                    affectedBy.insert(targetRootPath + source)
                }
            } else {
                if specificPath {
                    affectedBy.insert(targetRootPath)
                } else {
                    affectedBy.insert(targetRootPath + targetName)
                }
            }

            return PackageTargetMetadata(path: path,
                                         affectedBy: affectedBy,
                                         name: targetName,
                                         dependsOn: Set(dependencies),
                                         testTarget: type == "test")
        }
    }

    func targetIdentity() -> TargetIdentity {
        return TargetIdentity.package(path: path, targetName: name, testTarget: testTarget)
    }

    private static func isSwiftVersion6Plus() throws -> Bool {
        let versionString = try Shell.execOrFail("swift --version")
        let pattern = #"Apple Swift version (\d+)"#

        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return false
        }

        let range = NSRange(versionString.startIndex..<versionString.endIndex, in: versionString)
        if let match = regex.firstMatch(in: versionString, options: [], range: range),
           let majorVersionRange = Range(match.range(at: 1), in: versionString),
           let majorVersion = Int(versionString[majorVersionRange]),
           majorVersion > 5
        {
            return true
        } else {
            return false
        }
    }
}
