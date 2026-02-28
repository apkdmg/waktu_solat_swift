// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "WaktuSolatSwift",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "WaktuSolatSwift",
            targets: ["WaktuSolatSwift"]
        )
    ],
    targets: [
        .target(
            name: "WaktuSolatSwift"
        ),
        .testTarget(
            name: "WaktuSolatSwiftTests",
            dependencies: ["WaktuSolatSwift"]
        )
    ]
)
