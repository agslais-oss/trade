// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "ETFScreener",
    platforms: [.iOS(.v15), .macOS(.v12)],
    products: [
        .library(name: "ETFScreener", targets: ["ETFScreener"]),
    ],
    targets: [
        .target(name: "ETFScreener"),
    ]
)
