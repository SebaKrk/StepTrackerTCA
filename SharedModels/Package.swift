// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SharedModels",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v18),
        .watchOS(.v11)
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
        )
    ]
)
