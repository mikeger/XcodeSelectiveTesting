//
//  Created by Mike Gerasymenko <mike@gera.cx>
//

import Foundation
import PathKit
import Logging
import Workspace

public extension WorkspaceInfo {
    func affectedTargets(changedFiles: Set<Path>,
                         incldueIndirectlyAffected: Bool = true) -> Set<TargetIdentity> {
        var result = Set<TargetIdentity>()

        for path in changedFiles {
            if let targets = targetsForFiles[path] {
                result = result.union(targets)
            } else if let targetFromFolder = targetForFolder(path) {
                result.insert(targetFromFolder)
            } else {
                logger.info("Changed file at \(path) appears not to belong to any target")
            }
        }
        if incldueIndirectlyAffected {
            let indirectlyAffected = indirectlyAffectedTargets(targets: result)
            return result.union(indirectlyAffected)
        }
        else {
            return result
        }
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
