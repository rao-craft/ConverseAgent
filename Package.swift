// swift-tools-version:6.0
// ConverseAgent: a conversation's screens (the stage that types a reply out and brushes its sources' phrases, the
// transcript, the sources sheet and the woven reading) as plain SwiftUI any app that talks with a model can use,
// written into an app from its own types, as a Granite agent package. An app that links it finds the `converse` agent
// through Granite's roster, with nothing listed by hand.

import PackageDescription

let package = Package(
    name: "ConverseAgent",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "ConverseAgent", targets: ["ConverseAgent"]),
    ],
    dependencies: [
        .package(url: "https://github.com/riteshpakala/Granite.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "ConverseAgent",
            dependencies: [.product(name: "GraniteAgents", package: "Granite")],
            swiftSettings: [.swiftLanguageMode(.v6)]),
        .testTarget(
            name: "ConverseAgentTests",
            dependencies: ["ConverseAgent", .product(name: "GraniteAgents", package: "Granite")],
            swiftSettings: [.swiftLanguageMode(.v6)]),
    ]
)
