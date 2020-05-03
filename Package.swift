// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftGumbo",
    products: [
        .library(name: "SwiftGumbo", targets: ["SwiftGumbo"]),
    ],
    dependencies: [
        .package(name: "CGumboParser", url: "https://github.com/gshahbazian/gumbo-parser", .revision("795de2d0fdd9b58bb8b3e6ef962d718ab055a550")),
    ],
    targets: [
        .target(name: "SwiftGumbo", dependencies: ["CGumboParser"]),
        .testTarget(name: "SwiftGumboTests", dependencies: ["SwiftGumbo"]),
    ]
)
