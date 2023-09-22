//
//  Created by Mike Gerasymenko <mike@gera.cx>
//

import Foundation
import XCTest
@testable import DependencyCalculator
import Workspace
import PathKit
import SelectiveTestingCore

final class DependencyCalculatorTests: XCTestCase {
    
    func depStructure() -> (DependencyGraph, TargetIdentity, TargetIdentity, TargetIdentity, TargetIdentity, TargetIdentity, TargetIdentity) {
        let mainApp = TargetIdentity.project(projectPath: "/folder/Project.xcodepoj", name: "MainApp", testTarget: false)
        let mainAppTests = TargetIdentity.project(projectPath: "/folder/Project.xcodepoj", name: "MainAppTests", testTarget: true)
        
        let module = TargetIdentity.project(projectPath: "/folder/Project.xcodepoj", name: "Module", testTarget: false)
        let moduleTests = TargetIdentity.project(projectPath: "/folder/Project.xcodepoj", name: "ModuleTest", testTarget: true)
        
        let submodule = TargetIdentity.project(projectPath: "/folder/Project.xcodepoj", name: "SubModule", testTarget: false)
        let submoduleTests = TargetIdentity.project(projectPath: "/folder/Project.xcodepoj", name: "SubModuleTest", testTarget: true)
        
        var depGraph: [TargetIdentity: Set<TargetIdentity>] = [:]
        
        depGraph[mainApp] = Set([module])
        depGraph[mainAppTests] = Set([mainApp])
        
        depGraph[moduleTests] = Set([module])
        depGraph[module] = Set([submodule])
        
        depGraph[submoduleTests] = Set([submodule])
        
        let depsGraph = DependencyGraph(dependsOn: depGraph)
        
        return (depsGraph, mainApp, module, submodule, mainAppTests, moduleTests, submoduleTests)
    }
    
    func testGraphIntegrity_submodule() async throws {
        // given
        let (depsGraph, mainApp, module, submodule, mainAppTests, moduleTests, submoduleTests) = depStructure()
        
        let files = Set([Path("/folder/submodule/file.swift")])
        
        let graph = WorkspaceInfo(files: [submodule: files],
                                  folders: [:],
                                  dependencyStructure: depsGraph,
                                  candidateTestPlan: nil)
        // when
        
        let affected = graph.affectedTargets(changedFiles: files)
        
        // then
        XCTAssertEqual(affected, Set([mainApp, mainAppTests, module, moduleTests, submodule, submoduleTests]))
    }
    
    func testGraphIntegrity_mainApp() async throws {
        // given
        let (depsGraph, mainApp, _, _, mainAppTests, _, _) = depStructure()
        
        let files = Set([Path("/folder/submodule/file.swift")])
        
        let graph = WorkspaceInfo(files: [mainApp: files],
                                  folders: [:],
                                  dependencyStructure: depsGraph,
                                  candidateTestPlan: nil)
        // when
        
        let affected = graph.affectedTargets(changedFiles: files)
        
        // then
        XCTAssertEqual(affected, Set([mainApp, mainAppTests]))
    }
    
    func testGraphIntegrity_module() async throws {
        // given
        let (depsGraph, mainApp, module, _, mainAppTests, moduleTests, _) = depStructure()

        let files = Set([Path("/folder/submodule/file.swift")])
        
        let graph = WorkspaceInfo(files: [module: files],
                                  folders: [:],
                                  dependencyStructure: depsGraph,
                                  candidateTestPlan: nil)
        // when
        
        let affected = graph.affectedTargets(changedFiles: files)
        
        // then
        XCTAssertEqual(affected, Set([module, moduleTests, mainApp, mainAppTests]))
    }
}
