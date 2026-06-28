// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "HealthHub",
    platforms: [
        .iOS("26.0"),
    ],
    products: [
        .library(
            name: "HealthHub",
            targets: ["HealthHub"]),
    ],
    dependencies: [
        .package(path: "../Commons"),
        .package(path: "../SharedModels"),
        .package(path: "../AppDatabase"),
        .package(
            url: "https://github.com/pointfreeco/swift-composable-architecture.git",
            from: "1.26.0"
        ),
        .package(url: "https://github.com/pointfreeco/sqlite-data", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "HealthHub",
            dependencies: [
                "Commons",
                "SharedModels",
                "AppDatabase",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "SQLiteData", package: "sqlite-data")
            ]
        )
    ]
)
