// swift-tools-version:6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftObserver",
    platforms: [
        .iOS(.v13), .macOS(.v10_15), .tvOS(.v13), .macCatalyst(.v13), .visionOS(.v1), .watchOS(.v6)
    ],
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
