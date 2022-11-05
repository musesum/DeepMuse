// swift-tools-version:5.7

import PackageDescription

let package = Package(
    name: "MuColor",
    platforms: [
        .iOS(.v15),
        .tvOS(.v15),
        .watchOS(.v8),
    ],
    products: [
        .library(
            name: "MuColor",
            targets: ["MuColor"]),
    ],
    dependencies: [

    ],
    targets: [
        .target(
            name: "MuColor",
            dependencies: []),
        .testTarget(
            name: "MuColorTests",
            dependencies: ["MuColor"]),
    ]
)
