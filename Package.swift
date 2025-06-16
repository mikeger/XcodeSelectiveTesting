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
]

let targets: [PackageDescription.Target] = [
    .executableTarget(
        name: "xcode-selective-test",
        dependencies: [
            "SelectiveTestingCore",
            .product(name: "ArgumentParser", package: "swift-argument-parser"),
        ],
        swiftSettings: [.swiftLanguageMode(.v5)]
    ),
    .target(
        name: "SelectiveTestingCore",
        dependencies: [
            "DependencyCalculator",
            "TestConfigurator",
            "Git",
            "PathKit",
            "Rainbow",
            "Yams",
        ],
        swiftSettings: [.swiftLanguageMode(.v5)]
    ),
    .target(
        name: "DependencyCalculator",
        dependencies: ["Workspace", "PathKit", "SelectiveTestLogger", "Git"],
        swiftSettings: [.swiftLanguageMode(.v5)]
    ),
    .target(
        name: "TestConfigurator",
        dependencies: ["Workspace", "PathKit", "SelectiveTestLogger"],
        swiftSettings: [.swiftLanguageMode(.v5)]
    ),
    .target(
        name: "Workspace",
        dependencies: ["XcodeProj", "SelectiveTestLogger"],
        swiftSettings: [.swiftLanguageMode(.v5)]
    ),
    .target(
        name: "Git",
        dependencies: ["SelectiveTestShell", "SelectiveTestLogger", "PathKit"],
        swiftSettings: [.swiftLanguageMode(.v5)]
    ),
    .target(
        name: "SelectiveTestLogger",
        dependencies: ["Rainbow"],
        swiftSettings: [.swiftLanguageMode(.v5)]
    ),
    .target(name: "SelectiveTestShell", swiftSettings: [.swiftLanguageMode(.v5)]),
    .testTarget(
        name: "SelectiveTestingTests",
        dependencies: ["xcode-selective-test", "PathKit"],
        resources: [.copy("ExampleProject")],
        swiftSettings: [.swiftLanguageMode(.v5)]
    ),
    .testTarget(
        name: "DependencyCalculatorTests",
        dependencies: ["DependencyCalculator", "Workspace", "PathKit", "SelectiveTestingCore"],
        resources: [.copy("ExamplePackages")],
        swiftSettings: [.swiftLanguageMode(.v5)]
    ),
    .plugin(
        name: "SelectiveTestingPlugin",
        capability: .command(
            intent: .custom(
                verb: "xcode-selective-test",
                description: "Configure test plan for current changeset"
            ),
            permissions: [
                .writeToPackageDirectory(reason: "Update test plan file")
            ]
        ),
        dependencies: ["xcode-selective-test"]
    ),
]

let package = Package(
    name: "XcodeSelectiveTesting",
    platforms: [
        .macOS(.v12)
    ],
    products: products,
    dependencies: [
        .package(url: "https://github.com/tuist/XcodeProj.git", .upToNextMajor(from: "9.0.2")),
        .package(
            url: "https://github.com/apple/swift-argument-parser.git", .upToNextMajor(from: "1.2.0")
        ),
        .package(url: "https://github.com/kylef/PathKit.git", .upToNextMinor(from: "1.0.0")),
        .package(url: "https://github.com/onevcat/Rainbow", .upToNextMajor(from: "4.0.0")),
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.0.5"),
    ],
    targets: targets
)
