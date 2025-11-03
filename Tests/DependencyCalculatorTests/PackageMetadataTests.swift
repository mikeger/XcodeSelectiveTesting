//
//  Created by Mike Gerasymenko <mike@gera.cx>
//

@testable import DependencyCalculator
import Foundation
import PathKit
import Testing
@testable import Workspace

@Suite
struct PackageMetadataTests {
    @Test
    func packageMetadataParsing_Simple() throws {
        guard let exampleInBundle = Bundle.module.path(forResource: "ExamplePackages", ofType: "") else {
            fatalError("Missing ExamplePackages in TestBundle")
        }

        let basePath = Path(exampleInBundle) + "Simple"
        let metadata = try PackageTargetMetadata.parse(at: basePath)

        #expect(metadata.count == 2)
        let first = metadata[0]
        #expect(first.name == "ExampleSubpackage")
        #expect(first.path == basePath)
        #expect(first.dependsOn.isEmpty)
        #expect(first.affectedBy == Set([
            basePath + "Package.swift",
            basePath + "Package.resolved",
            basePath + "Sources" + "ExampleSubpackage",
            basePath + "Sources" + "ExampleSubpackage" + "Assets.xcassets"
        ]))

        let second = metadata[1]
        #expect(second.name == "ExampleSubpackageTests")
        #expect(second.path == basePath)
        #expect(second.dependsOn.count == 1)
        #expect(second.affectedBy == Set([
            basePath + "Package.swift",
            basePath + "Package.resolved",
            basePath + "Tests" + "ExampleSubpackageTests"
        ]))

        let identity = try #require(second.dependsOn.first)

        #expect(identity.type == .package)
        #expect(identity.path == basePath)
        #expect(identity.name == "ExampleSubpackage")
        #expect(!identity.isTestTarget)
    }

    @Test
    func packageMetadataParsing_ExamplePackage() throws {
        guard let exampleInBundle = Bundle.module.path(forResource: "ExamplePackages", ofType: "") else {
            fatalError("Missing ExamplePackages in TestBundle")
        }

        let basePath = Path(exampleInBundle) + "CrossDependency"
        let metadata = try PackageTargetMetadata.parse(at: basePath)

        #expect(metadata.count == 10)
        let first = metadata[0]
        #expect(first.name == "SelectiveTesting")
        #expect(first.path == basePath)
        #expect(first.dependsOn == Set([TargetIdentity.package(path: basePath, targetName: "SelectiveTestingCore", testTarget: false)]))
        #expect(first.affectedBy == Set([
            basePath + "Package.swift",
            basePath + "Package.resolved",
            basePath + "Sources" + "SelectiveTesting"
        ]))

        let second = metadata[1]
        #expect(second.name == "SelectiveTestingCore")
        #expect(second.path == basePath)
        #expect(second.dependsOn.count == 6)
        #expect(second.affectedBy == Set([
            basePath + "Package.swift",
            basePath + "Package.resolved",
            basePath + "Sources" + "SelectiveTestingCore"
        ]))
    }

    @Test
    func packageAndWorkspace() throws {
        guard let exampleInBundle = Bundle.module.path(forResource: "ExamplePackages", ofType: "") else {
            fatalError("Missing ExamplePackages in TestBundle")
        }

        let basePath = Path(exampleInBundle) + "PackageAndWorkspace"
        let metadata = try PackageTargetMetadata.parse(at: basePath)

        #expect(metadata.count == 2)
        let first = metadata[0]
        #expect(first.name == "APackage")
        #expect(first.path == basePath)
        #expect(first.dependsOn.isEmpty)
        #expect(first.affectedBy == Set([
            basePath + "Package.swift",
            basePath + "Package.resolved",
            basePath + "Sources" + "APackage"
        ]))

        let second = metadata[1]
        #expect(second.name == "APackageTests")
        #expect(second.path == basePath)
        #expect(second.dependsOn.count == 1)
        #expect(second.affectedBy == Set([
            basePath + "Package.swift",
            basePath + "Package.resolved",
            basePath + "Tests" + "APackageTests"
        ]))
    }
}
