// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Z-Paste",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "Z-Paste",
            targets: ["Z-Paste"]),
    ],
    dependencies: [
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "6.0.0"),
        .package(url: "https://github.com/sindresorhus/KeyboardShortcuts.git", from: "2.0.0")
    ],
    targets: [
        .executableTarget(
            name: "Z-Paste",
            dependencies: [
                .product(name: "GRDB", package: "GRDB.swift"),
                .product(name: "KeyboardShortcuts", package: "KeyboardShortcuts")
            ],
            path: "Z-Paste",
            exclude: [
                "Info.plist",
                "Z-Paste.entitlements"
            ]),
        .testTarget(
            name: "Z-PasteTests",
            dependencies: ["Z-Paste"],
            path: "Tests/Z-PasteTests"
        ),
    ]
)
