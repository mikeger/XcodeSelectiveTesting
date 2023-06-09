// swift-tools-version: 5.6

import PackageDescription

let package = Package(
    name: "SelectiveTesting",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(name: "SelectiveTesting", targets: ["SelectiveTesting"])
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
            dependencies: ["SelectiveTestingCore", .product(name: "ArgumentParser", package: "swift-argument-parser")],
            swiftSettings: [
                .unsafeFlags(["-warnings-as-errors"])
            ]),
        .target(name: "SelectiveTestingCore",
                dependencies: ["DependencyCalculator",
                               "TestConfigurator",
                               "Git",
                               "PathKit",
                               "Rainbow"],
                swiftSettings: [
                    .unsafeFlags(["-warnings-as-errors"])
                ]),
        .target(name: "DependencyCalculator", dependencies: ["Workspace", "PathKit", "Logger", "Git"],
                swiftSettings: [
                    .unsafeFlags(["-warnings-as-errors"])
                ]),
        .target(name: "TestConfigurator", dependencies: ["Workspace", "PathKit", "Logger"],
                swiftSettings: [
                    .unsafeFlags(["-warnings-as-errors"])
                ]),
        .target(name: "Workspace", dependencies: ["XcodeProj", "Logger"],
                swiftSettings: [
                    .unsafeFlags(["-warnings-as-errors"])
                ]),
        .target(name: "Git", dependencies: ["Shell", "Logger", "PathKit"],
                swiftSettings: [
                    .unsafeFlags(["-warnings-as-errors"])
                ]),
        .target(name: "Logger", dependencies: ["Rainbow"],
                swiftSettings: [
                    .unsafeFlags(["-warnings-as-errors"])
                ]),
        .target(name: "Shell",
                swiftSettings: [
                    .unsafeFlags(["-warnings-as-errors"])
                ]),
        .testTarget(
            name: "SelectiveTestingTests",
            dependencies: ["SelectiveTesting", "PathKit"],
            resources: [.copy("ExampleProject")]),
        .testTarget(
            name: "DependencyCalculatorTests",
            dependencies: ["DependencyCalculator", "Workspace", "PathKit", "SelectiveTestingCore"]),
    ]
)
