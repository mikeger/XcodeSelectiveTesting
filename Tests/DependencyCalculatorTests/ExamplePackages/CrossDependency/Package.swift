// swift-tools-version: 5.6

import PackageDescription

let sharedSettings: [SwiftSetting] = [
    .unsafeFlags(["-warnings-as-errors"]),
]

let package = Package(
    name: "XcodeSelectiveTesting",
    platforms: [
        .macOS(.v12),
    ],
    products: [
        .executable(name: "xcode-selective-test", targets: ["SelectiveTesting"]),
    ],
    dependencies: [
        .package(url: "https://github.com/tuist/XcodeProj.git", .upToNextMajor(from: "8.9.0")),
        .package(url: "https://github.com/apple/swift-argument-parser.git", .upToNextMajor(from: "1.2.0")),
        .package(url: "https://github.com/kylef/PathKit.git", .upToNextMinor(from: "1.0.0")),
        .package(url: "https://github.com/onevcat/Rainbow", .upToNextMajor(from: "4.0.0")),
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.0.5"),
    ],
    targets: [
        .executableTarget(
            name: "SelectiveTesting",
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
                dependencies: ["Workspace", "PathKit", "Logger", "Git"],
                swiftSettings: sharedSettings),
        .target(name: "TestConfigurator",
                dependencies: ["Workspace", "PathKit", "Logger"],
                swiftSettings: sharedSettings),
        .target(name: "Workspace",
                dependencies: ["XcodeProj", "Logger"],
                swiftSettings: sharedSettings),
        .target(name: "Git",
                dependencies: ["Shell", "Logger", "PathKit"],
                swiftSettings: sharedSettings),
        .target(name: "Logger",
                dependencies: ["Rainbow"],
                swiftSettings: sharedSettings),
        .target(name: "Shell",
                swiftSettings: sharedSettings),
        .testTarget(
            name: "SelectiveTestingTests",
            dependencies: ["SelectiveTesting", "PathKit"],
            resources: [.copy("ExampleProject")]
        ),
        .testTarget(
            name: "DependencyCalculatorTests",
            dependencies: ["DependencyCalculator", "Workspace", "PathKit", "SelectiveTestingCore"],
            resources: [.copy("ExamplePackages")]
        ),
    ]
)
