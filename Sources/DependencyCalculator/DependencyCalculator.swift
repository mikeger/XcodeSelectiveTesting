//
//  Created by Mike Gerasymenko <mike@gera.cx>
//

import Foundation
import Workspace
import PathKit
import SelectiveTestLogger
import Git

public struct ChangedTarget: Hashable {
    let target: TargetIdentity
    enum ChangeType: Hashable {
        case direct(lines: Int)
        case indirect(by: TargetIdentity)
    }
    let changeType: ChangeType
}

extension WorkspaceInfo {
    public func affectedTargets(changedFiles: Set<ChangesetMetadata>) -> Set<ChangedTarget> {
        var result = Set<ChangedTarget>()
        
        changedFiles.forEach { metadata in
            
            if let targets = targetsForFiles[metadata.path] {
                result = result.union(targets.map({ targetIdentity in
                    ChangedTarget(target: targetIdentity, changeType: .direct(lines: metadata.changedLines))
                }))
            }
            else if let targetFromFolder = targetForFolder(metadata.path) {
                result.insert(ChangedTarget(target: targetFromFolder, changeType: .direct(lines: metadata.changedLines)))
            }
            else {
                Logger.message("Changed file at \(metadata.path) appears not to belong to any target")
            }
        }

        let indirectlyAffected = indirectlyAffectedTargets(targets: result)
        
        return result.union(indirectlyAffected)
    }
    
    func targetForFolder(_ path: Path) -> TargetIdentity? {
        return folders.first { (folder, target) in
            path.string.contains(folder.string + "/")
        }?.value
    }
    
    public func indirectlyAffectedTargets(targets: Set<ChangedTarget>) -> Set<ChangedTarget> {
        var result = Set<TargetIdentity>()
        
        targets.forEach { targetAffected in
            let affected = dependencyStructure.affected(by: targetAffected.target).map { targetIdentity in
                ChangedTarget(target: targetIdentity, changeType: .indirect(by: targetAffected))
            }
            let nextLevelAffected = indirectlyAffectedTargets(targets: affected)
            result = result.union(affected).union(nextLevelAffected)
        }
        
        return result
    }
}
