//
//  Created by Mike Gerasymenko <mike@gera.cx>
//

import Foundation
import Workspace
import PathKit
import Logger

extension WorkspaceInfo {
    public func affectedTargets(changedFiles: Set<Path>) -> Set<TargetIdentity> {
        var result = Set<TargetIdentity>()
        
        changedFiles.forEach { path in
            
            if let target = self.targetsForFiles[path] {
                result.insert(target)
            }
            else {
                Logger.message("Changed file at \(path) appears not to belong to any target")
            }
        }
        
        let indirectlyAffected = indirectlyAffectedTargets(targets: result)
        return result.union(indirectlyAffected)
    }
    
    public func indirectlyAffectedTargets(targets: Set<TargetIdentity>) -> Set<TargetIdentity> {
        var result = Set<TargetIdentity>()
        
        targets.forEach { targetAffected in
            let affected = self.dependencyStructure.affected(by: targetAffected)
            let nextLevelAffected = self.indirectlyAffectedTargets(targets: affected)
            result = result.union(affected).union(nextLevelAffected)
        }
        
        return result
    }
}
