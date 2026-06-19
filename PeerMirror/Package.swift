// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PeerMirror",
    platforms: [
        .iOS("26.0"),
        .tvOS("26.0")
    ],
    products: [
        .library(
            name: "PeerMirror",
            targets: ["PeerMirror"]),
    ],
    dependencies: [
        .package(path: "../SharedModels"),
        .package(
            url: "https://github.com/pointfreeco/swift-composable-architecture.git",
            from: "1.26.0"
        ),
    ],
    targets: [
        .target(
            name: "PeerMirror",
            dependencies: [
                "SharedModels",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ]
        )
    ]
)
