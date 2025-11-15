// swift-tools-version: 6.0

import PackageDescription

let products: [PackageDescription.Product] = [
    .executable(
        name: "xcode-selective-test",
        targets: ["xcode-selective-test"]
    ),
    .plugin(
        name: "XcodeSelectiveTest",
        targets: ["SelectiveTestingPlugin"]
    ),
    .library(
        name: "XcodeSelectiveTestCore",
        targets: ["SelectiveTestingCore"]
    )
]

let flags: [PackageDescription.SwiftSetting] = [.enableExperimentalFeature("StrictConcurrency")]

let targets: [PackageDescription.Target] = [
    .executableTarget(
        name: "xcode-selective-test",
        dependencies: ["SelectiveTestingCore",
                       .product(name: "ArgumentParser", package: "swift-argument-parser")],
        swiftSettings: flags
    ),
    .target(name: "SelectiveTestingCore",
            dependencies: ["DependencyCalculator",
                           "TestConfigurator",
                           "Git",
                           "PathKit",
                           "Yams",
                           .product(name: "ArgumentParser", package: "swift-argument-parser")],
            swiftSettings: flags
    ),
    .target(name: "DependencyCalculator",
            dependencies: ["Workspace", "PathKit", "Git", .product(name: "Logging", package: "swift-log")],
            swiftSettings: flags
    ),
    .target(name: "TestConfigurator",
            dependencies: [
                "Workspace",
                "PathKit",
                .product(name: "Logging", package: "swift-log"),
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ],
            swiftSettings: flags
    ),
    .target(name: "Workspace",
            dependencies: ["XcodeProj", .product(name: "Logging", package: "swift-log")],
            swiftSettings: flags
    ),
    .target(name: "Git",
            dependencies: ["SelectiveTestShell", "PathKit", .product(name: "Logging", package: "swift-log")],
            swiftSettings: flags
    ),
    .target(name: "SelectiveTestShell",
            swiftSettings: flags
    ),
    .testTarget(
        name: "SelectiveTestingTests",
        dependencies: ["xcode-selective-test", "PathKit", "Workspace"],
        resources: [.copy("ExampleProject")],
        swiftSettings: flags
    ),
    .testTarget(
        name: "DependencyCalculatorTests",
        dependencies: ["DependencyCalculator", "Workspace", "PathKit", "SelectiveTestingCore"],
        resources: [.copy("ExamplePackages")],
        swiftSettings: flags
    ),
    .plugin(
        name: "SelectiveTestingPlugin",
        capability: .command(
            intent: .custom(
                verb: "xcode-selective-test",
                description: "Configure test plan for current changeset"
            ),
            permissions: [
                .writeToPackageDirectory(reason: "Update test plan file"),
            ]
        ),
        dependencies: ["xcode-selective-test"]
    )
]

let package = Package(
    name: "XcodeSelectiveTesting",
    platforms: [
        .macOS(.v12),
    ],
    products: products,
    dependencies: [
        .package(url: "https://github.com/tuist/XcodeProj.git", .upToNextMajor(from: "9.0.2")),
        .package(url: "https://github.com/apple/swift-argument-parser.git", .upToNextMajor(from: "1.2.0")),
        .package(url: "https://github.com/kylef/PathKit.git", .upToNextMinor(from: "1.0.0")),
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.0.5"),
        .package(url: "https://github.com/apple/swift-log", from: "1.6.0")
    ],
    targets: targets
)
