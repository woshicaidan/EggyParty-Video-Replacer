// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "蛋仔开屏动画替换工具",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .executable(
            name: "PartyScreenReplacer",
            targets: ["PartyScreenReplacer"]
        )
    ],
    dependencies: [

    ],
    targets: [
        .executableTarget(
            name: "PartyScreenReplacer",
            dependencies: [],
            path: "Sources/PartyScreenReplacer",
            resources: [
                .process("Assets.xcassets")
            ],
            swiftSettings: [
                .define("DEBUG", .when(configuration: .debug))
            ]
        )
    ]
)