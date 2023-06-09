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
            
            if let targets = self.targetsForFiles[path] {
                result = result.union(targets)
            }
            else if let targetFromFolder = self.targetForFolder(path) {
                result.insert(targetFromFolder)
            }
            else {
                Logger.warning("Changed file at \(path) appears not to belong to any target")
            }
        }
        
        let indirectlyAffected = indirectlyAffectedTargets(targets: result)
        return result.union(indirectlyAffected)
    }
    
    func targetForFolder(_ path: Path) -> TargetIdentity? {
        return self.folders.first { (folder, target) in
            path.string.contains(folder.string)
        }?.value
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
