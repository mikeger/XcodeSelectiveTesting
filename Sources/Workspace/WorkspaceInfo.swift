//
//  Created by Mike Gerasymenko <mike@gera.cx>
//

import Foundation
import PathKit
import Logging
import XcodeProj

public extension Dictionary where Key == TargetIdentity, Value == Set<Path> {
    func merging(with other: Self) -> Self {
        merging(other, uniquingKeysWith: { first, second in
            first.union(second)
        })
    }
}

public extension Dictionary where Key == Path, Value == TargetIdentity {
    func merging(with other: Self) -> Self {
        merging(other, uniquingKeysWith: { _, second in
            second
        })
    }
}

public struct WorkspaceInfo {
    public let files: [TargetIdentity: Set<Path>]
    public let targetsForFiles: [Path: Set<TargetIdentity>]
    public let folders: [Path: TargetIdentity]
    public let dependencyStructure: DependencyGraph
    public var candidateTestPlans: [String]

    /// Backwards compatibility: returns the first candidate test plan
    public var candidateTestPlan: String? {
        candidateTestPlans.first
    }

    public init(files: [TargetIdentity: Set<Path>],
                folders: [Path: TargetIdentity],
                dependencyStructure: DependencyGraph,
                candidateTestPlan: String?)
    {
        self.files = files
        targetsForFiles = WorkspaceInfo.targets(for: files)
        self.folders = folders
        self.dependencyStructure = dependencyStructure
        self.candidateTestPlans = candidateTestPlan.map { [$0] } ?? []
    }

    public init(files: [TargetIdentity: Set<Path>],
                folders: [Path: TargetIdentity],
                dependencyStructure: DependencyGraph,
                candidateTestPlans: [String])
    {
        self.files = files
        targetsForFiles = WorkspaceInfo.targets(for: files)
        self.folders = folders
        self.dependencyStructure = dependencyStructure
        self.candidateTestPlans = candidateTestPlans
    }

    public func merging(with other: WorkspaceInfo) -> WorkspaceInfo {
        let newFiles = files.merging(with: other.files)
        let newFolders = folders.merging(with: other.folders)
        let dependencyStructure = dependencyStructure.merging(with: other.dependencyStructure)
        let mergedTestPlans = candidateTestPlans + other.candidateTestPlans

        return WorkspaceInfo(files: newFiles,
                             folders: newFolders,
                             dependencyStructure: dependencyStructure,
                             candidateTestPlans: mergedTestPlans)
    }

    static func targets(for targetsToFiles: [TargetIdentity: Set<Path>]) -> [Path: Set<TargetIdentity>] {
        var result: [Path: Set<TargetIdentity>] = [:]
        for (target, files) in targetsToFiles {
            for path in files {
                var existing = result[path] ?? Set()
                existing.insert(target)
                result[path] = existing
            }
        }
        return result
    }
}

public extension WorkspaceInfo {
    struct AdditionalConfig: Codable {
        public init(targetsFiles: [String: [String]],
                    dependencies: [String: [String]])
        {
            self.targetsFiles = targetsFiles
            self.dependencies = dependencies
        }

        public let targetsFiles: [String: [String]]
        public let dependencies: [String: [String]]
    }
}

public extension WorkspaceInfo {
    func pruningDisconnectedTargets() -> WorkspaceInfo {
        let projectTargets = Set(files.keys.filter { $0.type == .project })
        guard !projectTargets.isEmpty else { return self }

        var reachable = dependencyStructure.reachableTargets(startingFrom: projectTargets).union(projectTargets)
        guard !reachable.isEmpty else { return self }

        let reachablePackageRoots = Set(reachable
            .filter { $0.type == .package }
            .map { $0.path })

        if !reachablePackageRoots.isEmpty {
            for target in files.keys where target.type == .package && reachablePackageRoots.contains(target.path) {
                reachable.insert(target)
            }
        }

        let filteredFiles = files.filter { reachable.contains($0.key) }
        let filteredFolders = folders.filter { reachable.contains($0.value) }
        let filteredDependencies = dependencyStructure.filteringTargets(reachable)

        return WorkspaceInfo(files: filteredFiles,
                             folders: filteredFolders,
                             dependencyStructure: filteredDependencies,
                             candidateTestPlans: candidateTestPlans)
    }
}
