// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Seagull",
    products: [
        .library(name: "Seagull", targets: ["Seagull"]),
        .executable(name: "SgSimpleServer", targets: ["SgSimpleServer"]),
        .executable(name: "SgBaseRest", targets: ["SgBaseRest"]),
    ],
    dependencies: [
        .package(url: "https://github.com/antitypical/Result.git", from: "4.0.0"),
        .package(url: "https://github.com/apple/swift-nio.git", from: "1.0.0"),
    ],
    targets: [
        .target(name: "Seagull", dependencies: ["NIO", "NIOHTTP1", "NIOConcurrencyHelpers", "Result"]),
        .target(name: "SgSimpleServer", dependencies: ["Seagull"], path: "Sources/Examples/SimpleServer"),
        .target(name: "SgBaseRest", dependencies: ["Seagull"], path: "Sources/Examples/BaseRest"),
        .testTarget(name: "SeagullTests", dependencies: ["Seagull"]),
    ]
)
