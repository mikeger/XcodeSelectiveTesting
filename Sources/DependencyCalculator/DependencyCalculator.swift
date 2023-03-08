//
//  Created by Mike Gerasymenko <mike@gera.cx>
//

import Foundation
import Workspace
import PathKit

extension WorkspaceInfo {
    
    public func affectedTargets(changedFiles: Set<Path>) -> Set<TargetIdentity> {
        return Set() // TODO
    }
    
    func indirectlyAffectedTargets(targets: Set<TargetIdentity>) -> Set<TargetIdentity> {
        return Set() // TODO
    }
}
