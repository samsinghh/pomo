// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "pomo",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.5.0"),
    ],
    targets: [
        .target(name: "PomoKit"),
        .executableTarget(
            name: "pomo",
            dependencies: [
                "PomoKit",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]),
        .testTarget(name: "PomoKitTests", dependencies: ["PomoKit"]),
    ]
)
