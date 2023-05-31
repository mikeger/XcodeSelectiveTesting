//
//  Created by Mike Gerasymenko <mike@gera.cx>
//

import Foundation
import Workspace
import PathKit
import XcodeProj
import Workspace
import Logger

extension String: Error {}

extension XCScheme {
    static func findScheme(in projects: [(XcodeProj, Path)], name schemeName: String) -> (XCScheme, XCSharedData)? {
        var scheme: XCScheme? = nil
        var sharedData: XCSharedData? = nil
        
        projects.forEach { (proj, path) in
            proj.userData.forEach { userData in
                userData.schemes.forEach { someScheme in
                    if someScheme.name == schemeName {
                        scheme = someScheme
                        sharedData = sharedData
                    }
                }
            }

            proj.sharedData?.schemes.forEach { someScheme in
                if someScheme.name == schemeName {
                    scheme = someScheme
                    sharedData = proj.sharedData
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
            throw "Error: Scheme \(scheme.name) does not have a test plan. Please convert it to use a test plan."
        }
    }
    
    func enableTestsInTestPlan(testsInTargets: Set<TargetIdentity>, scheme: XCScheme) throws {
        scheme.testAction?.testPlans?.forEach { testPlanReference in
            print(testPlanReference.reference)
        }
    }
    
}
    
public func enableTests(at path: Path, scheme schemeName: String, targetsToTest: Set<TargetIdentity>) throws {
    
    let projects: [(XcodeProj, Path)]
    
    if path.extension == "xcworkspace" {
        projects = try XCWorkspace(path: path).allProjects(basePath: path.parent())
    }
    else {
        projects = [(try XcodeProj(path: path), path)]
    }
    
    guard let (schemeToConfigure, sharedData) = XCScheme.findScheme(in: projects, name: schemeName) else {
        throw "Scheme \(schemeName) not found"
    }
    
    try sharedData.enable(testsInTargets: targetsToTest, scheme: schemeToConfigure)
}
