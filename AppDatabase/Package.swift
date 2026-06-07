// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "AppDatabase",
    defaultLocalization: "en",
    platforms: [
        .iOS("26.0")
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
        .package(path: "../SharedModels")
    ],
    targets: [
        .target(
            name: "AppDatabase",
            dependencies: [
                .product(name: "SQLiteData", package: "sqlite-data"),
                .product(name: "Dependencies", package: "swift-dependencies"),
                "SharedModels"
            ]
        )
    ]
)
