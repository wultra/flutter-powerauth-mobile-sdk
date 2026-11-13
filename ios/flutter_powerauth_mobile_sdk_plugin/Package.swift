
// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "flutter_powerauth_mobile_sdk_plugin",
    platforms: [
        .iOS("15.0"),
    ],
    products: [
        // If the plugin name contains "_", replace with "-" for the library name.
        .library(name: "flutter-powerauth-mobile-sdk-plugin", targets: ["flutter_powerauth_mobile_sdk_plugin"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework"),
        // Mirrors the CocoaPods `PowerAuth2` dependency (`~> 2.1.0`).
        .package(url: "https://github.com/wultra/powerauth-mobile-sdk", .upToNextMinor(from: "2.1.0")),
    ],
    targets: [
        .target(
            name: "flutter_powerauth_mobile_sdk_plugin",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework"),
                .product(name: "PowerAuth2", package: "powerauth-mobile-sdk"),
            ]
        )
    ]
)
