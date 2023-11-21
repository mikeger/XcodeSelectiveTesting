//
//  Created by Mike Gerasymenko <mike@gera.cx>
//

import Foundation
import PathKit
import Workspace
import SelectiveTestLogger

extension TestPlanHelper {
    static func updateSelectedTestTargets(testPlan: inout TestPlanModel,
                                          with targets: Set<TargetIdentity>) {
        checkForTestTargets(testPlan: testPlan)
        
        let packagesToTest = Set<String>(targets.compactMap { target in
            switch target.type {
            case .package:
                return target.name
            case .project:
                return nil
            }
        })
        
        let targetsToTest = Set<String>(targets.compactMap { target in
            switch target.type {
            case .package:
                return nil
            case .project:
                return target.name
            }
        })
        
        testPlan.testTargets = testPlan.testTargets.map { target in
            let enabled = targetsToTest.contains(target.target.name) ||
                            packagesToTest.contains(target.target.name)
            
            return TestTarget(parallelizable: target.parallelizable,
                              skippedTests: target.skippedTests,
                              selectedTests: target.selectedTests,
                              target: target.target,
                              enabled: enabled)
        }
    }
}

public func enableTests(at testPlanPath: Path, targetsToTest: Set<TargetIdentity>) throws {
    var testPlan = try TestPlanHelper.readTestPlan(filePath: testPlanPath.string)

    TestPlanHelper.updateSelectedTestTargets(testPlan: &testPlan, with: targetsToTest)

    try TestPlanHelper.writeTestPlan(testPlan, filePath: testPlanPath.string)
}
