// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "ShimmerKit",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .tvOS(.v15),
        .watchOS(.v8),
        .visionOS(.v1),
    ],
    products: [
        .library(name: "ShimmerKit", targets: ["ShimmerKit"]),
    ],
    targets: [
        .target(name: "ShimmerKit"),
        .testTarget(name: "ShimmerKitTests", dependencies: ["ShimmerKit"]),
    ]
)
