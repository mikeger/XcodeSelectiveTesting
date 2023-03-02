// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "TestChanged",
    dependencies: [
        .package(url: "https://github.com/tuist/XcodeProj.git", .upToNextMajor(from: "8.9.0")),
        .package(url: "https://github.com/apple/swift-argument-parser.git", .upToNextMajor(from: "1.2.0")),
        .package(url: "https://github.com/kylef/PathKit.git", .upToNextMinor(from: "1.0.0")),
    ],
    targets: [
        .executableTarget(
            name: "TestChanged",
            dependencies: ["TestChangedCore", .product(name: "ArgumentParser", package: "swift-argument-parser")]),
        .target(name: "TestChangedCore", dependencies: ["XcodeProj", "PathKit"]),
        .testTarget(
            name: "TestChangedTests",
            dependencies: ["TestChanged"]),
    ]
)
