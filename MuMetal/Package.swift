// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MuMetal",
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "MuMetal",
            targets: ["MuMetal"]),
    ],
    dependencies: [
        .package(url: "https://github.com/musesum/MuFlo.git", from: "0.23.0"),
    ],
    targets: [
        .target(
            name: "MuMetal",
            dependencies: [
                .product(name: "MuFlo", package: "MuFlo"),
            ]),
        .testTarget(
            name: "MuMetalTests",
            dependencies: ["MuMetal"]),
    ]
)
