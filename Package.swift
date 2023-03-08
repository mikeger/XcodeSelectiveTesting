// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "TestChanged",
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
            name: "TestChanged",
            dependencies: ["TestChangedCore", .product(name: "ArgumentParser", package: "swift-argument-parser")]),
        
            .target(name: "TestChangedCore", dependencies: ["DependencyCalculator",
                                                            "DependencyGraph",
                                                            "TestConfigurator",
                                                            "Changeset",
                                                            "PathKit",
                                                            "Rainbow"]),
        .target(name: "DependencyCalculator", dependencies: ["Workspace", "PathKit", "Logger"]),
        .target(name: "DependencyGraph", dependencies: ["Workspace", "PathKit", "Logger"]),
        .target(name: "TestConfigurator", dependencies: ["Workspace", "PathKit", "Logger"]),
        .target(name: "Workspace", dependencies: ["XcodeProj", "Logger"]),
        .target(name: "Changeset", dependencies: ["Shell", "Logger"]),
        .target(name: "Logger", dependencies: ["Rainbow"]),
        .target(name: "Shell"),
        .testTarget(
            name: "TestChangedTests",
            dependencies: ["TestChanged", "PathKit"],
            resources: [.copy("../ExampleProject")]),
    ]
)
