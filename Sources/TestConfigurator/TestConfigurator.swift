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
        
        var newTestTargets: [TestTarget] = []
        
        testPlan.testTargets.forEach { target in
            if targetsToTest.contains(target.target.name) {
                var newTarget = target
                newTarget.selectedTests = []
                newTarget.skippedTests = []
                newTestTargets.append(newTarget)
            }
        }
        
        testPlan.testTargets = newTestTargets
    }
}

public func enableTests(at testPlanPath: Path, targetsToTest: Set<TargetIdentity>) throws {
    var testPlan = try TestPlanHelper.readTestPlan(filePath: testPlanPath.string)

    TestPlanHelper.updateSelectedTestTargets(testPlan: &testPlan, with: targetsToTest)

    try TestPlanHelper.writeTestPlan(testPlan, filePath: testPlanPath.string)
}
