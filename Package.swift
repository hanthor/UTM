// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "UTM",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "UTMApp", targets: ["UTMApp"]),
        .library(name: "Configuration", targets: ["Configuration"])
    ],
    dependencies: [
        .package(url: "https://github.com/AparokshaUI/Adwaita", from: "0.1.0")
    ],
    targets: [
        .target(
            name: "UTMApp",
            dependencies: [
                .product(name: "Adwaita", package: "Adwaita"),
                "Configuration"
            ],
            path: "Platform/Linux"
        ),
        .target(
            name: "Configuration",
            dependencies: [],
            path: "Configuration",
            exclude: ["Legacy"]
        )
    ]
)
