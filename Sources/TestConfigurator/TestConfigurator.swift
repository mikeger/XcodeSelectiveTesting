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
        
        let packagesToTest = Set<String>(targets.compactMap { target in
            switch target {
            case .swiftPackage(_, let name):
                return name
            case .target(_, _):
                return nil
            }
        })
        
        let targetsToTest = Set<String>(targets.compactMap { target in
            switch target {
            case .swiftPackage(_, _):
                return nil
            case .target(_, let name):
                return name
            }
        })
        
        testPlan.testTargets = testPlan.testTargets.filter { target in
            return targetsToTest.contains(target.target.name) ||
                    packagesToTest.contains(target.target.name)
        }
    }
}

public func enableTests(at testPlanPath: Path, targetsToTest: Set<TargetIdentity>) throws {
    var testPlan = try TestPlanHelper.readTestPlan(filePath: testPlanPath.string)

    TestPlanHelper.updateSelectedTestTargets(testPlan: &testPlan, with: targetsToTest)

    try TestPlanHelper.writeTestPlan(testPlan, filePath: testPlanPath.string)
}
