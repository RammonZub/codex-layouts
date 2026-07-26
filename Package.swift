// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "CodexLayouts",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .executable(name: "CodexLayouts", targets: ["CodexLayouts"])
    ],
    targets: [
        .executableTarget(
            name: "CodexLayouts",
            linkerSettings: [
                .linkedFramework("ApplicationServices"),
                .linkedFramework("Carbon"),
                .linkedLibrary("sqlite3")
            ]
        ),
        .testTarget(
            name: "CodexLayoutsTests",
            dependencies: ["CodexLayouts"]
        )
    ]
)
