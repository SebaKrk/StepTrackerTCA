// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "HealthHub",
    platforms: [
        .iOS(.v17),
        .watchOS(.v10)
    ],
    products: [
        .library(
            name: "HealthHub",
            targets: ["HealthHub"]),
    ],
    dependencies: [
        .package(path: "../Commons")
    ],
    targets: [
        .target(
            name: "HealthHub",
            dependencies: ["Commons"])
        // Usuń testTarget - nie masz foldera Tests
    ]
)
