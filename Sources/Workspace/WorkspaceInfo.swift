//
//  Created by Mike Gerasymenko <mike@gera.cx>
//

import Foundation
import PathKit
import XcodeProj
import Logger

public extension Dictionary where Key == TargetIdentity, Value == Set<Path> {
    func merging(with other: Self) -> Self {
        self.merging(other, uniquingKeysWith: { first, second in
            first.union(second)
        })
    }
}

public extension Dictionary where Key == Path, Value == TargetIdentity {
    func merging(with other: Self) -> Self {
        self.merging(other, uniquingKeysWith: { first, second in
             second
        })
    }
}

public struct WorkspaceInfo {
    public let files: [TargetIdentity: Set<Path>]
    public let targetsForFiles: [Path: Set<TargetIdentity>]
    public let folders: [Path: TargetIdentity]
    public let dependencyStructure: DependencyGraph
    public var candidateTestPlan: String?
    
    public init(files: [TargetIdentity: Set<Path>],
                folders: [Path: TargetIdentity],
                dependencyStructure: DependencyGraph,
                candidateTestPlan: String?) {
        self.files = files
        self.targetsForFiles = WorkspaceInfo.targets(for: files)
        self.folders = folders
        self.dependencyStructure = dependencyStructure
        self.candidateTestPlan = candidateTestPlan
    }
    
    public func merging(with other: WorkspaceInfo) -> WorkspaceInfo {
        let newFiles = files.merging(with: other.files)
        let newFolders = folders.merging(with: other.folders)
        let dependencyStructure = dependencyStructure.merging(with: other.dependencyStructure)
        
        return WorkspaceInfo(files: newFiles,
                             folders: newFolders,
                             dependencyStructure: dependencyStructure,
                             candidateTestPlan: self.candidateTestPlan ?? other.candidateTestPlan)
    }
    
    static func targets(for targetsToFiles: [TargetIdentity: Set<Path>]) -> [Path: Set<TargetIdentity>] {
        var result: [Path: Set<TargetIdentity>] = [:]
        targetsToFiles.forEach { (target, files) in
            files.forEach { path in
                var existing = result[path] ?? Set()
                existing.insert(target)
                result[path] = existing
            }
        }
        return result
    }
}

extension WorkspaceInfo {
    public struct AdditionalConfig: Codable {
        public init(targetsFiles: [String: [String]],
                    dependencies: [String: [String]]) {
            self.targetsFiles = targetsFiles
            self.dependencies = dependencies
        }
        public let targetsFiles: [String: [String]]
        public let dependencies: [String: [String]]
    }
}
