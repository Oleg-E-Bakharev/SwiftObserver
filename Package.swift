// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftObserver",
    products: [
        .library(
            name: "SwiftObserver",
            targets: ["SwiftObserver"]),
    ],
    targets: [
        .target(
            name: "SwiftObserver",
            dependencies: []),
        .testTarget(
            name: "SwiftObserverTests",
            dependencies: ["SwiftObserver"]),
    ]
)
