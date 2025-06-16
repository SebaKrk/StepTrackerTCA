// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Commons",
    platforms: [
        .iOS(.v17),
        .watchOS(.v11)
    ],
    products: [
        .library(
            name: "Commons",
            targets: ["Commons"]),
    ],
    dependencies: [
        // Na razie brak zewnętrznych zależności
    ],
    targets: [
        .target(
            name: "Commons",
            dependencies: [])
    ]
)
