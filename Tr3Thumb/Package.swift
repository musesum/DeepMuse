// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "Tr3Thumb",
    platforms: [
        .macOS(.v10_14),
        .iOS(.v12),
        .tvOS(.v12),
        .watchOS(.v4),
    ],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "Tr3Thumb",
            targets: ["Tr3Thumb"]),
    ],
    dependencies: [
        .package(url: "https://github.com/musesum/Tr3.git", from: "0.1.2"),
        //.package(path: "../Tr3"),
        .package(path: "../MuCubic"),
        .package(path: "../MuUtilities"),
    ],
    targets: [
        .target(
            name: "Tr3Thumb",
            dependencies: ["Tr3","MuCubic","MuUtilities"]),
        .testTarget(
            name: "Tr3ThumbTests",
            dependencies: ["Tr3Thumb"]),
    ]
)
