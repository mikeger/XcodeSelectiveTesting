// swift-tools-version: 5.6

import PackageDescription

let sharedSettings: [SwiftSetting] = [
    .unsafeFlags(["-warnings-as-errors"]),
]

let products: [PackageDescription.Product] = [
    .executable(
        name: "xcode-selective-test",
        targets: ["xcode-selective-test"]
    ),
    .plugin(
        name: "XcodeSelectiveTest",
        targets: ["SelectiveTestingPlugin"]
    ),
]

let targets: [PackageDescription.Target] = [
    .executableTarget(
        name: "xcode-selective-test",
        dependencies: ["SelectiveTestingCore",
                       .product(name: "ArgumentParser", package: "swift-argument-parser")],
        swiftSettings: sharedSettings
    ),
    .target(name: "SelectiveTestingCore",
            dependencies: ["DependencyCalculator",
                           "TestConfigurator",
                           "Git",
                           "PathKit",
                           "Rainbow",
                           "Yams"],
            swiftSettings: sharedSettings),
    .target(name: "DependencyCalculator",
            dependencies: ["Workspace", "PathKit", "SelectiveTestLogger", "Git"],
            swiftSettings: sharedSettings),
    .target(name: "TestConfigurator",
            dependencies: ["Workspace", "PathKit", "SelectiveTestLogger"],
            swiftSettings: sharedSettings),
    .target(name: "Workspace",
            dependencies: ["XcodeProj", "SelectiveTestLogger"],
            swiftSettings: sharedSettings),
    .target(name: "Git",
            dependencies: ["SelectiveTestShell", "SelectiveTestLogger", "PathKit"],
            swiftSettings: sharedSettings),
    .target(name: "SelectiveTestLogger",
            dependencies: ["Rainbow"],
            swiftSettings: sharedSettings),
    .target(name: "SelectiveTestShell",
            swiftSettings: sharedSettings),
    .testTarget(
        name: "SelectiveTestingTests",
        dependencies: ["xcode-selective-test", "PathKit"],
        resources: [.copy("ExampleProject")]
    ),
    .testTarget(
        name: "DependencyCalculatorTests",
        dependencies: ["DependencyCalculator", "Workspace", "PathKit", "SelectiveTestingCore"],
        resources: [.copy("ExamplePackages")]
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
    ),
]

let package = Package(
    name: "XcodeSelectiveTesting",
    platforms: [
        .macOS(.v12),
    ],
    products: products,
    dependencies: [
        .package(url: "https://github.com/tuist/XcodeProj.git", .upToNextMajor(from: "8.16.0")),
        .package(url: "https://github.com/apple/swift-argument-parser.git", .upToNextMajor(from: "1.2.0")),
        .package(url: "https://github.com/kylef/PathKit.git", .upToNextMinor(from: "1.0.0")),
        .package(url: "https://github.com/onevcat/Rainbow", .upToNextMajor(from: "4.0.0")),
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.0.5"),
    ],
    targets: targets
)
