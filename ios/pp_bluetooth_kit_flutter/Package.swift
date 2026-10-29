// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "pp_bluetooth_kit_flutter",
    platforms: [.iOS("15.0")],
    products: [
        .library(name: "pp-bluetooth-kit-flutter", targets: ["pp_bluetooth_kit_flutter"]),
        // The calculator must link the same PPBaseKit as BLE. Export it rather
        // than allowing a second copy of the static vendor SDK into the app.
        .library(name: "PPBaseKit", targets: ["PPBaseKit"]),
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework"),
        // Match the app's existing CocoaPods lockfile and keep iOS 15 support.
        .package(url: "https://github.com/ZipArchive/ZipArchive.git", exact: "2.4.3"),
    ],
    targets: [
        .binaryTarget(name: "PPBaseKit", path: "Frameworks/PPBaseKit.xcframework"),
        .binaryTarget(name: "PPBluetoothKit", path: "Frameworks/PPBluetoothKit.xcframework"),
        .target(
            name: "pp_bluetooth_kit_flutter",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework"),
                .product(name: "ZipArchive", package: "ZipArchive"),
                "PPBaseKit",
                "PPBluetoothKit",
            ],
            // SwiftPM flattens the static graph into the app. -all_load would
            // also load duplicate C objects in PPBasicCalculateKit; -ObjC
            // retains SDK categories without force-loading those objects.
            linkerSettings: [.unsafeFlags(["-ObjC"])]
        ),
    ]
)
