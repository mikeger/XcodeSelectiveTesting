// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ExamplePackage",
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "ExamplePackage",
            targets: ["ExamplePackage"]
        ),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(path: "../ExampleSubpackage"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "ExamplePackage",
            dependencies: ["ExampleSubpackage"],
            resources: [.copy("Resouces"), .process("Resouces 2")]
        ),
        .testTarget(
            name: "ExamplePackageTests",
            dependencies: ["ExamplePackage"]
        ),
        .binaryTarget(
            name: "BinaryTarget",
            path: "Binary.xcframework"
        ),
        .testTarget(
            name: "Subtests",
            dependencies: ["ExamplePackage"]
        ),
    ]
)
