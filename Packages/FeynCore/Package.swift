// swift-tools-version: 6.0
import PackageDescription

// Platform-neutral core for Feyn: tutoring policy, engine interface, cloud client.
// Keep this package free of Apple-only frameworks so it builds and tests on Linux.
let package = Package(
    name: "FeynCore",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [.library(name: "FeynCore", targets: ["FeynCore"])],
    targets: [
        .target(name: "FeynCore"),
        .testTarget(name: "FeynCoreTests", dependencies: ["FeynCore"]),
    ]
)
