// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftWLR",
    products: [
        .library(name: "Cwlroots", targets: ["Cwlroots"]),
        .library(name: "SwiftWLR", targets: ["SwiftWLR"]),
        .executable(name: "TinyWL", targets: ["TinyWL"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftwayland/SwiftWayland.git", .branch("master")),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
    ],
    targets: [
        .systemLibrary(
            name: "Cwlroots",
            pkgConfig: "wlroots"
        ),
        .target(
            name: "SwiftWLR",
            dependencies: ["Cwayland", "Cwlroots", "SwiftWayland", "Logging"],
            cSettings: [
                .define("WLR_USE_UNSTABLE"),
                .headerSearchPath("External"),
            ]
        ),
        .target(
            name: "TinyWL",
            dependencies: ["Cwlroots", "SwiftWayland", "SwiftWLR", "Logging"]
        ),
    ]
)
