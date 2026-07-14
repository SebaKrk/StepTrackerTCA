// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SharedModels",
    defaultLocalization: "en",
    platforms: [
        .iOS("26.0"),
        .watchOS("26.0"),
        .macOS("26.0"),
        .tvOS("26.0")
    ],
    products: [
        .library(
            name: "SharedModels",
            targets: ["SharedModels"]),
    ],
    dependencies: [
        .package(path: "../Commons")
    ],
    targets: [
        .target(
            name: "SharedModels",
            dependencies: ["Commons"],
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "SharedModelsTests",
            dependencies: ["SharedModels"]
        )
    ]
)
