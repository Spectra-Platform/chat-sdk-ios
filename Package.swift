// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "SpectraChatSDK",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
    ],
    products: [
        .library(
            name: "SpectraChatSDK",
            targets: ["SpectraChatSDK"]
        ),
    ],
    targets: [
        .target(
            name: "SpectraChatSDK"
        ),
        .testTarget(
            name: "SpectraChatSDKTests",
            dependencies: ["SpectraChatSDK"]
        ),
    ]
)
