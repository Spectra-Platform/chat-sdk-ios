// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "SpectraChatSDK",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "SpectraChatSDK",
            targets: ["SpectraChatSDK"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/Spectra-Platform/auth-sdk-ios.git", .upToNextMinor(from: "0.1.2")),
        .package(url: "https://github.com/Spectra-Platform/storage-sdk-ios.git", .upToNextMinor(from: "0.1.1")),
    ],
    targets: [
        .target(
            name: "SpectraChatSDK",
            dependencies: [
                .product(name: "SpectraStorageSDK", package: "storage-sdk-ios"),
                .product(name: "SpectraAuthSDK", package: "auth-sdk-ios"),
            ]
        ),
        .testTarget(
            name: "SpectraChatSDKTests",
            dependencies: [
                "SpectraChatSDK",
                .product(name: "SpectraStorageSDK", package: "storage-sdk-ios"),
                .product(name: "SpectraAuthSDK", package: "auth-sdk-ios"),
            ]
        ),
    ]
)
