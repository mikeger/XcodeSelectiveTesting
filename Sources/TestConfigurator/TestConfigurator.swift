//
//  Created by Mike Gerasymenko <mike@gera.cx>
//

import Foundation
import Workspace
import PathKit
import XcodeProj
import Workspace
import Logger

extension XCScheme {
    static func findScheme(in projects: [(XcodeProj, Path)], name schemeName: String) -> (XCScheme, XCSharedData)? {
        var scheme: XCScheme? = nil
        var sharedData: XCSharedData? = nil
        
        projects.forEach { (proj, path) in
            proj.sharedData?.schemes.forEach { someScheme in
                if someScheme.name == schemeName {
                    scheme = someScheme
                    sharedData = sharedData
                }
            }
        }
        if let scheme, let sharedData {
            return (scheme, sharedData)
        }
        else {
            return nil
        }
    }
    
    func isTestPlanBased() -> Bool {
        self.testAction?.testPlans != nil
    }
    
}

extension XCSharedData {
    
    func enable(testsInTargets: Set<TargetIdentity>, scheme: XCScheme) throws {
        
        if scheme.isTestPlanBased() {
            try enableTestsInTestPlan(testsInTargets: testsInTargets, scheme: scheme)
        }
        else {
            try enableTestsInScheme(testsInTargets: testsInTargets, scheme: scheme)
        }
    }
    
    func enableTestsInTestPlan(testsInTargets: Set<TargetIdentity>, scheme: XCScheme) throws {
        scheme.testAction?.testPlans?.forEach { testPlanReference in
//            Logger.warning(testPlanReference.reference)
            // TODO: Implement disabling all tests in the testPlan and enabling ones in testsInTargets
        }
    }
    
    func enableTestsInScheme(testsInTargets: Set<TargetIdentity>, scheme: XCScheme) throws {
        scheme.testAction?.testables.forEach { testable in
//            testable.selectedTests = []
            
//            testable.skippedTests
            // TODO: Implement disabling all tests in the testAction and enabling ones in testsInTargets
        }
        
//        self.write
    }
}
    
public func enableTests(at path: Path, scheme schemeName: String, targetsToTest: Set<TargetIdentity>) throws {
    
    let projects: [(XcodeProj, Path)]
    
    if path.extension == "xcworkspace" {
        projects = try XCWorkspace(path: path).allProjects(basePath: path)
    }
    else {
        projects = [(try XcodeProj(path: path), path)]
    }
    
    guard let (schemeToConfigure, sharedData) = XCScheme.findScheme(in: projects, name: schemeName) else {
        throw "Scheme \(schemeName) not found"
    }
    
    try sharedData.enable(testsInTargets: targetsToTest, scheme: schemeToConfigure)
}
