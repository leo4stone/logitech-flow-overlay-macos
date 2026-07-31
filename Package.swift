// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "LogitechFlowOverlay",
    platforms: [.macOS(.v13)],
    products: [
        .executable(
            name: "LogitechFlowOverlay",
            targets: ["LogitechFlowOverlay"]
        )
    ],
    targets: [
        .executableTarget(
            name: "LogitechFlowOverlay",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("IOKit")
            ]
        ),
        .testTarget(
            name: "LogitechFlowOverlayTests",
            dependencies: ["LogitechFlowOverlay"]
        )
    ]
)
