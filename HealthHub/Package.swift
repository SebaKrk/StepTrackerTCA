// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "HealthHub",
    platforms: [
        .iOS(.v17),
        .watchOS(.v11)
    ],
    products: [
        .library(
            name: "HealthHub",
            targets: ["HealthHub"]),
    ],
    dependencies: [
        .package(path: "../Commons"),
        .package(path: "../SharedModels"),
        .package(
            url: "https://github.com/pointfreeco/swift-composable-architecture.git",
            from: "1.20.2" 
        ),
    ],
    targets: [
        .target(
            name: "HealthHub",
            dependencies: [
                "Commons",
                "SharedModels",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ]
        )
    ]
)
