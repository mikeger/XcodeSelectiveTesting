//
//  Created by Mike Gerasymenko <mike@gera.cx>
//

@testable import DependencyCalculator
import Foundation
import PathKit
import SelectiveTestingCore
import Testing
import Workspace

@Suite
struct DependencyCalculatorTests {
    func depStructure() -> (DependencyGraph, TargetIdentity, TargetIdentity, TargetIdentity, TargetIdentity, TargetIdentity, TargetIdentity) {
        let mainApp = TargetIdentity.project(path: "/folder/Project.xcodepoj", targetName: "MainApp", testTarget: false)
        let mainAppTests = TargetIdentity.project(path: "/folder/Project.xcodepoj", targetName: "MainAppTests", testTarget: true)

        let module = TargetIdentity.project(path: "/folder/Project.xcodepoj", targetName: "Module", testTarget: false)
        let moduleTests = TargetIdentity.project(path: "/folder/Project.xcodepoj", targetName: "ModuleTest", testTarget: true)

        let submodule = TargetIdentity.project(path: "/folder/Project.xcodepoj", targetName: "SubModule", testTarget: false)
        let submoduleTests = TargetIdentity.project(path: "/folder/Project.xcodepoj", targetName: "SubModuleTest", testTarget: true)

        var depGraph: [TargetIdentity: Set<TargetIdentity>] = [:]

        depGraph[mainApp] = Set([module])
        depGraph[mainAppTests] = Set([mainApp])

        depGraph[moduleTests] = Set([module])
        depGraph[module] = Set([submodule])

        depGraph[submoduleTests] = Set([submodule])

        let depsGraph = DependencyGraph(dependsOn: depGraph)

        return (depsGraph, mainApp, module, submodule, mainAppTests, moduleTests, submoduleTests)
    }

    @Test
    func graphIntegrity_submodule() async throws {
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
        #expect(affected == Set([mainApp, mainAppTests, module, moduleTests, submodule, submoduleTests]))
    }

    @Test
    func graphIntegrity_mainApp() async throws {
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
        #expect(affected == Set([mainApp, mainAppTests]))
    }

    @Test
    func graphIntegrity_module() async throws {
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
        #expect(affected == Set([module, moduleTests, mainApp, mainAppTests]))
    }
}
