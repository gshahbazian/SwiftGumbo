// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftGumbo",
    products: [
        .library(name: "SwiftGumbo", targets: ["SwiftGumbo"]),
    ],
    dependencies: [
        .package(url: "https://github.com/gshahbazian/gumbo-parser", .branch("master")),
    ],
    targets: [
        .target(name: "SwiftGumbo", dependencies: ["CGumboParser"]),
        .testTarget(name: "SwiftGumboTests", dependencies: ["SwiftGumbo"]),
    ]
)
