// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Seagull",
    products: [
        .library(name: "Seagull", targets: ["Seagull"]),
        .executable(name: "Simple", targets: ["Simple"]),
        .executable(name: "Rest", targets: ["Rest"]),
    ],
    dependencies: [
        .package(url: "https://github.com/antitypical/Result.git", from: "4.0.0"),
        .package(url: "https://github.com/apple/swift-nio.git", from: "1.0.0"),
    ],
    targets: [
        .target(name: "Seagull", dependencies: ["NIO", "NIOHTTP1", "NIOConcurrencyHelpers", "Result"]),
        .target(name: "Simple", dependencies: ["Seagull"], path: "Sources/Examples/Simple"),
        .target(name: "Rest", dependencies: ["Seagull"], path: "Sources/Examples/Rest"),
        .testTarget(name: "SeagullTests", dependencies: ["Seagull"]),
    ]
)
