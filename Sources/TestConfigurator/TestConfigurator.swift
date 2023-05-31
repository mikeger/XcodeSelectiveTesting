//
//  Created by Mike Gerasymenko <mike@gera.cx>
//

import Foundation
import PathKit
import Workspace
import Logger

extension TestPlanHelper {
    static func updateSelectedTestTargets(testPlan: inout TestPlanModel, with targets: Set<TargetIdentity>) {
        checkForTestTargets(testPlan: testPlan)
        
        let targetsToTest = Set(targets.map { target in
            switch target {
            case .swiftPackage(_, let name):
                return name
            case .target(_, let name):
                return name
            }
        })
        
        for (index, _) in testPlan.testTargets.enumerated() {
            if targetsToTest.contains(testPlan.testTargets[index].target.name) {
                testPlan.testTargets[index].selectedTests = []
                testPlan.testTargets[index].skippedTests = []
            }
        }
    }
}

public func enableTests(at testPlanPath: Path, targetsToTest: Set<TargetIdentity>) throws {
    var testPlan = try TestPlanHelper.readTestPlan(filePath: testPlanPath.string)
        
    TestPlanHelper.updateSelectedTestTargets(testPlan: &testPlan, with: targetsToTest)
    
    try TestPlanHelper.writeTestPlan(testPlan, filePath: testPlanPath.string)
}
