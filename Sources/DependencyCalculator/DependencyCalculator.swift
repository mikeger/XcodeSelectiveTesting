//
//  Created by Mike Gerasymenko <mike@gera.cx>
//

import Foundation
import PathKit
import SelectiveTestLogger
import Workspace

public extension WorkspaceInfo {
    func affectedTargets(changedFiles: Set<Path>) -> Set<TargetIdentity> {
        var result = Set<TargetIdentity>()

        for path in changedFiles {
            if let targets = targetsForFiles[path] {
                result = result.union(targets)
            } else if let targetFromFolder = targetForFolder(path) {
                result.insert(targetFromFolder)
            } else {
                Logger.message("Changed file at \(path) appears not to belong to any target")
            }
        }

        let indirectlyAffected = indirectlyAffectedTargets(targets: result)
        return result.union(indirectlyAffected)
    }

    internal func targetForFolder(_ path: Path) -> TargetIdentity? {
        return folders.first { folder, _ in
            path.string.contains(folder.string + "/")
        }?.value
    }

    func indirectlyAffectedTargets(targets: Set<TargetIdentity>) -> Set<TargetIdentity> {
        var result = Set<TargetIdentity>()

        for targetAffected in targets {
            let affected = dependencyStructure.affected(by: targetAffected)
            let nextLevelAffected = indirectlyAffectedTargets(targets: affected)
            result = result.union(affected).union(nextLevelAffected)
        }

        return result
    }
}
