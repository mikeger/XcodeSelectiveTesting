//
//  Created by Mike Gerasymenko <mike@gera.cx>
//

import Foundation
import Workspace
import PathKit
import SelectiveTestLogger

extension WorkspaceInfo {
    public func affectedTargets(changedFiles: Set<Path>) -> Set<TargetIdentity> {
        var result = Set<TargetIdentity>()
        
        changedFiles.forEach { path in
            
            if let targets = targetsForFiles[path] {
                result = result.union(targets)
            }
            else if let targetFromFolder = targetForFolder(path) {
                result.insert(targetFromFolder)
            }
            else {
                Logger.message("Changed file at \(path) appears not to belong to any target")
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
    
    public func indirectlyAffectedTargets(targets: Set<TargetIdentity>) -> Set<TargetIdentity> {
        var result = Set<TargetIdentity>()
        
        targets.forEach { targetAffected in
            let affected = dependencyStructure.affected(by: targetAffected)
            let nextLevelAffected = indirectlyAffectedTargets(targets: affected)
            result = result.union(affected).union(nextLevelAffected)
        }
        
        return result
    }
}
