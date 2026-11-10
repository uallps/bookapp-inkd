// swift-tools-version: 6.4
import PackageDescription

let package = Package(
    name: "InkdApp",
    dependencies: [
        .package(
            url: "https://github.com/moreSwift/swift-cross-ui",
            .upToNextMinor(from: "0.10.0")
        )
    ],
    targets: [
        .executableTarget(
            name: "InkdApp",
            dependencies: [
                .product(name: "SwiftCrossUI", package: "swift-cross-ui"),
                .product(name: "DefaultBackend", package: "swift-cross-ui")
            ]
        ),
        .testTarget(
            name: "InkdAppTests",
            dependencies: ["InkdApp"]
        )
    ]
)
