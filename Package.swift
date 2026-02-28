// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "BrewNotifier",
    platforms: [.macOS(.v13)],
    targets: [
        .target(
            name: "BrewNotifierCore",
            path: "Sources/BrewNotifierCore"
        ),
        .executableTarget(
            name: "BrewNotifier",
            dependencies: ["BrewNotifierCore"],
            path: "Sources/BrewNotifier",
            exclude: ["Info.plist"],
            resources: [
                .process("Resources")
            ],
            swiftSettings: [
                .unsafeFlags(["-parse-as-library"])
            ]
        ),
        .testTarget(
            name: "BrewNotifierTests",
            dependencies: ["BrewNotifierCore"],
            path: "Tests/BrewNotifierTests"
        )
    ]
)
