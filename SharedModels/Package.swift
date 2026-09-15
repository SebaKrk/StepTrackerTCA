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
        // NOTE: IssueReporting is declared via its historical URL — the app's
        // package graph pins it there (transitively via sqlite-data), and the
        // new swift-issue-reporting URL would be a duplicate-identity conflict.
        .package(url: "https://github.com/pointfreeco/xctest-dynamic-overlay", from: "1.0.0"),
        .package(path: "../Commons")
    ],
    targets: [
        .target(
            name: "SharedModels",
            dependencies: [
                .product(name: "IssueReporting", package: "xctest-dynamic-overlay"),
                "Commons"
            ],
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "SharedModelsTests",
            dependencies: ["SharedModels"]
        )
    ]
)
