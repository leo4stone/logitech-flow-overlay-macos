// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "InputLinkTips",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "InputLinkTips", targets: ["InputLinkTips"])
    ],
    targets: [
        .executableTarget(
            name: "InputLinkTips",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("IOKit")
            ]
        ),
        .testTarget(
            name: "InputLinkTipsTests",
            dependencies: ["InputLinkTips"]
        )
    ]
)
