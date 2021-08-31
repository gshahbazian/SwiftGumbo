// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftGumbo",
    products: [
        .library(name: "SwiftGumbo", targets: ["SwiftGumbo"]),
        .library(name: "CGumboParser", targets: ["CGumboParser"]),
    ],
    targets: [
        .target(name: "SwiftGumbo", dependencies: ["CGumboParser"]),
        .testTarget(name: "SwiftGumboTests", dependencies: ["SwiftGumbo"]),
        .target(
            name: "CGumboParser",
            sources: [
                "ascii.c",
                "attribute.c",
                "char_ref.c",
                "error.c",
                "foreign_attrs.c",
                "parser.c",
                "string_buffer.c",
                "svg_attrs.c",
                "svg_tags.c",
                "tag_lookup.c",
                "tag.c",
                "tokenizer.c",
                "utf8.c",
                "util.c",
                "vector.c",
            ]
        ),
    ],
    cLanguageStandard: .c99
)
