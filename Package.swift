// swift-tools-version:6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftObserver",
//    platforms: [
//        .iOS(.v15),
//    ],
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
