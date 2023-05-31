//
//  Created by Mike Gerasymenko <mike@gera.cx>
//

import Foundation
import PathKit
import Workspace
import Logger

public func enableTests(at testPlanPath: Path, targetsToTest: Set<TargetIdentity>) throws {
    
    let testPlan = try TestPlanHelper.readTestPlan(filePath: testPlanPath.string)
        
//    TestPlanHelper.updateSelectedTests(testPlan: &testPlan, with: tests, override: false)
    
    try TestPlanHelper.writeTestPlan(testPlan, filePath: testPlanPath.string)
}
