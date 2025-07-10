//
//  Created by Mike Gerasymenko <mike@gera.cx>
//

@testable import DependencyCalculator
import Foundation
import PathKit
@testable import Workspace
import XCTest

final class PackageMetadataTests: XCTestCase {
    func testPackageMetadataParsing_Simple() throws {
        // given
        guard let exampleInBundle = Bundle.module.path(forResource: "ExamplePackages", ofType: "") else {
            fatalError("Missing ExamplePackages in TestBundle")
        }
        // when
        let basePath = Path(exampleInBundle) + "Simple"
        let metadata = try PackageTargetMetadata.parse(at: basePath)

        // then
        XCTAssertEqual(metadata.count, 2)
        let first = metadata[0]
        XCTAssertEqual(first.name, "ExampleSubpackage")
        XCTAssertEqual(first.path, basePath)
        XCTAssertEqual(first.dependsOn.count, 0)
        XCTAssertEqual(first.affectedBy, Set([
            basePath + "Package.swift",
            basePath + "Package.resolved",
            basePath + "Sources" + "ExampleSubpackage",
            basePath + "Sources" + "ExampleSubpackage" + "Assets.xcassets"
        ]))

        let second = metadata[1]
        XCTAssertEqual(second.name, "ExampleSubpackageTests")
        XCTAssertEqual(second.path, basePath)
        XCTAssertEqual(second.dependsOn.count, 1)
        XCTAssertEqual(second.affectedBy, Set([
            basePath + "Package.swift",
            basePath + "Package.resolved",
            basePath + "Tests" + "ExampleSubpackageTests"
        ]))

        let identity = try XCTUnwrap(second.dependsOn.first)

        XCTAssertEqual(identity.type, .package)
        XCTAssertEqual(identity.path, basePath)
        XCTAssertEqual(identity.name, "ExampleSubpackage")
        XCTAssertFalse(identity.isTestTarget)
    }

    func testPackageMetadataParsing_ExamplePacakge() throws {
        // given
        guard let exampleInBundle = Bundle.module.path(forResource: "ExamplePackages", ofType: "") else {
            fatalError("Missing ExamplePackages in TestBundle")
        }
        // when
        let basePath = Path(exampleInBundle) + "CrossDependency"
        let metadata = try PackageTargetMetadata.parse(at: basePath)

        // then
        XCTAssertEqual(metadata.count, 10)
        let first = metadata[0]
        XCTAssertEqual(first.name, "SelectiveTesting")
        XCTAssertEqual(first.path, basePath)
        XCTAssertEqual(first.dependsOn, Set([TargetIdentity.package(path: basePath, targetName: "SelectiveTestingCore", testTarget: false)]))
        XCTAssertEqual(first.affectedBy, Set([
            basePath + "Package.swift",
            basePath + "Package.resolved",
            basePath + "Sources" + "SelectiveTesting"
        ]))

        let second = metadata[1]
        XCTAssertEqual(second.name, "SelectiveTestingCore")
        XCTAssertEqual(second.path, basePath)
        XCTAssertEqual(second.dependsOn.count, 6)
        XCTAssertEqual(second.affectedBy, Set([
            basePath + "Package.swift",
            basePath + "Package.resolved",
            basePath + "Sources" + "SelectiveTestingCore"
        ]))
    }
    
    func testPackageAndWorkspace() async throws {
        // given
        guard let exampleInBundle = Bundle.module.path(forResource: "ExamplePackages", ofType: "") else {
            fatalError("Missing ExamplePackages in TestBundle")
        }
        // when
        let basePath = Path(exampleInBundle) + "PackageAndWorkspace"
        let metadata = try PackageTargetMetadata.parse(at: basePath)

        // then
        XCTAssertEqual(metadata.count, 2)
        let first = metadata[0]
        XCTAssertEqual(first.name, "APackage")
        XCTAssertEqual(first.path, basePath)
        XCTAssertEqual(first.dependsOn, Set([]))
        XCTAssertEqual(first.affectedBy, Set([
            basePath + "Package.swift",
            basePath + "Package.resolved",
            basePath + "Sources" + "APackage"
        ]))

        let second = metadata[1]
        XCTAssertEqual(second.name, "APackageTests")
        XCTAssertEqual(second.path, basePath)
        XCTAssertEqual(second.dependsOn.count, 1)
        XCTAssertEqual(second.affectedBy, Set([
            basePath + "Package.swift",
            basePath + "Package.resolved",
            basePath + "Tests" + "APackageTests"
        ]))
    }
}
