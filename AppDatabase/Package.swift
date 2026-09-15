// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "AppDatabase",
    defaultLocalization: "en",
    platforms: [
        .iOS("26.0"),
        .macOS("26.0")
    ],
    products: [
        .library(
            name: "AppDatabase",
            targets: ["AppDatabase"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/sqlite-data", from: "1.0.0"),
        .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.0.0"),
        // NOTE: the graph pins IssueReporting under its historical URL
        // (xctest-dynamic-overlay, via sqlite-data) — using the new
        // swift-issue-reporting URL creates a duplicate-identity conflict.
        .package(url: "https://github.com/pointfreeco/xctest-dynamic-overlay", from: "1.0.0"),
        .package(path: "../SharedModels")
    ],
    targets: [
        .target(
            name: "AppDatabase",
            dependencies: [
                .product(name: "SQLiteData", package: "sqlite-data"),
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "IssueReporting", package: "xctest-dynamic-overlay"),
                "SharedModels"
            ]
        ),
        .testTarget(
            name: "AppDatabaseTests",
            dependencies: ["AppDatabase"]
        )
    ]
)
