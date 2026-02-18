// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "HogBar",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .executable(name: "HogBar", targets: ["HogBar"]),
    ],
    targets: [
        .executableTarget(
            name: "HogBar",
            path: "Sources/HogBar"
        ),
        .testTarget(
            name: "HogBarTests",
            dependencies: ["HogBar"],
            path: "Tests/HogBarTests"
        ),
    ]
)
