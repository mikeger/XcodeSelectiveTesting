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

    @Test
    func filtersUnreferencedPackagesWhenWorkspaceHasProjects() throws {
        let project = TargetIdentity.project(path: Path("/workspace/App.xcodeproj"),
                                             targetName: "App",
                                             testTarget: false)
        let usedPackage = TargetIdentity.package(path: Path("/workspace/Packages/Used"),
                                                 targetName: "UsedTarget",
                                                 testTarget: false)
        let unusedPackage = TargetIdentity.package(path: Path("/workspace/Packages/Unused"),
                                                   targetName: "UnusedTarget",
                                                   testTarget: false)

        let files: [TargetIdentity: Set<Path>] = [
            project: [Path("/workspace/App/App.swift")],
            usedPackage: [Path("/workspace/Packages/Used/Source.swift")],
            unusedPackage: [Path("/workspace/Packages/Unused/Source.swift")]
        ]

        let dependencies = DependencyGraph(dependsOn: [
            project: Set([usedPackage]),
            usedPackage: Set()
        ])

        let info = WorkspaceInfo(files: files,
                                 folders: [:],
                                 dependencyStructure: dependencies,
                                 candidateTestPlan: nil)

        let pruned = info.pruningDisconnectedTargets()

        #expect(pruned.files.keys.contains(project))
        #expect(pruned.files.keys.contains(usedPackage))
        #expect(!pruned.files.keys.contains(unusedPackage))
    }

    @Test
    func keepsPackagesWhenNoProjectsPresent() throws {
        let packageA = TargetIdentity.package(path: Path("/workspace/Packages/A"),
                                              targetName: "ATarget",
                                              testTarget: false)
        let packageB = TargetIdentity.package(path: Path("/workspace/Packages/B"),
                                              targetName: "BTarget",
                                              testTarget: false)

        let files: [TargetIdentity: Set<Path>] = [
            packageA: [Path("/workspace/Packages/A/file.swift")],
            packageB: [Path("/workspace/Packages/B/file.swift")]
        ]

        let dependencies = DependencyGraph(dependsOn: [
            packageA: Set([packageB])
        ])

        let info = WorkspaceInfo(files: files,
                                 folders: [:],
                                 dependencyStructure: dependencies,
                                 candidateTestPlan: nil)

        let pruned = info.pruningDisconnectedTargets()

        #expect(pruned.files.keys == files.keys)
    }
}
