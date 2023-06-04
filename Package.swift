// swift-tools-version: 5.6

import PackageDescription

let package = Package(
    name: "SelectiveTesting",
    platforms: [
        .macOS(.v12)
    ],
    dependencies: [
        .package(url: "https://github.com/tuist/XcodeProj.git", .upToNextMajor(from: "8.9.0")),
        .package(url: "https://github.com/apple/swift-argument-parser.git", .upToNextMajor(from: "1.2.0")),
        .package(url: "https://github.com/kylef/PathKit.git", .upToNextMinor(from: "1.0.0")),
        .package(url: "https://github.com/onevcat/Rainbow", .upToNextMajor(from: "4.0.0")),
    ],
    targets: [
        .executableTarget(
            name: "SelectiveTesting",
            dependencies: ["SelectiveTestingCore", .product(name: "ArgumentParser", package: "swift-argument-parser")]),
        .target(name: "SelectiveTestingCore", dependencies: ["DependencyCalculator",
                                                            "TestConfigurator",
                                                            "Git",
                                                            "PathKit",
                                                            "Rainbow"]),
        .target(name: "DependencyCalculator", dependencies: ["Workspace", "PathKit", "Logger", "Git"]),
        .target(name: "TestConfigurator", dependencies: ["Workspace", "PathKit", "Logger"]),
        .target(name: "Workspace", dependencies: ["XcodeProj", "Logger"]),
        .target(name: "Git", dependencies: ["Shell", "Logger", "PathKit"]),
        .target(name: "Logger", dependencies: ["Rainbow"]),
        .target(name: "Shell"),
        .testTarget(
            name: "SelectiveTestingTests",
            dependencies: ["SelectiveTesting", "PathKit"],
            resources: [.copy("ExampleProject")]),
        .testTarget(
            name: "DependencyCalculatorTests",
            dependencies: ["DependencyCalculator", "Workspace", "PathKit", "SelectiveTestingCore"]),
    ]
)
