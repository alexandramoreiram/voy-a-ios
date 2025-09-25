// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "VoyA",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .executable(name: "VoyA", targets: ["VoyA"])
    ],
    targets: [
        .executableTarget(
            name: "VoyA",
            path: "Sources"
        )
    ]
)
