// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Seagull",
    products: [
        .library(name: "Seagull", targets: ["Seagull"]),
        .executable(name: "SeagullRestDemo", targets: ["SeagullRestDemo"]),
        .executable(name: "SeagullPerfTest", targets: ["SeagullPerfTest"]),
    ],
    dependencies: [
        .package(url: "https://github.com/antitypical/Result.git", from: "4.0.0"),
        .package(url: "https://github.com/apple/swift-nio.git", from: "1.9.5"),
        .package(url: "https://github.com/gavrilaf/SwiftPerfTool.git", from: "0.1.0"),
        .package(url: "https://github.com/gavrilaf/SgRouter.git", from: "0.1.0"),
    ],
    targets: [
        .target(name: "Seagull", dependencies: ["NIO", "NIOHTTP1", "NIOConcurrencyHelpers", "Result", "SgRouter"]),
        .target(name: "SeagullRestDemo", dependencies: ["Seagull"], path: "Sources/Examples/SeagullRestDemo"),
        .target(name: "SeagullPerfTest", dependencies: ["Seagull", "SwiftPerfTool"], path: "Sources/Examples/SeagullPerfTest"),
        .testTarget(name: "SeagullTests", dependencies: ["Seagull"]),
    ]
)
