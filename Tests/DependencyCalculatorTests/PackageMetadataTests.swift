//
//  Created by Mike Gerasymenko <mike@gera.cx>
//

import Foundation
import XCTest
import PathKit
@testable import Workspace
@testable import DependencyCalculator

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
        XCTAssertEqual(first.affectedBy, Set([basePath + "Package.swift",
                                              basePath + "Sources" + "ExampleSubpackage",
                                              basePath + "Sources" + "ExampleSubpackage" + "Assets.xcassets"]))

        let second = metadata[1]
        XCTAssertEqual(second.name, "ExampleSubpackageTests")
        XCTAssertEqual(second.path, basePath)
        XCTAssertEqual(second.dependsOn.count, 1)
        XCTAssertEqual(second.affectedBy, Set([basePath + "Package.swift", basePath + "Tests" + "ExampleSubpackageTests"]))

        if case let TargetIdentity.package(path, name, test) = try XCTUnwrap(second.dependsOn.first) {
            XCTAssertEqual(path, basePath)
            XCTAssertEqual(name, "ExampleSubpackage")
            XCTAssertFalse(test)
        }
        else {
            XCTFail()
        }
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
        XCTAssertEqual(first.dependsOn, Set([TargetIdentity.package(path: basePath, name: "SelectiveTestingCore", testTarget: false)]))
        XCTAssertEqual(first.affectedBy, Set([basePath + "Package.swift", basePath + "Sources" + "SelectiveTesting"]))
        
        let second = metadata[1]
        XCTAssertEqual(second.name, "SelectiveTestingCore")
        XCTAssertEqual(second.path, basePath)
        XCTAssertEqual(second.dependsOn.count, 6)
        XCTAssertEqual(second.affectedBy, Set([basePath + "Package.swift", basePath + "Sources" + "SelectiveTestingCore"]))
    }
}
