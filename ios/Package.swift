// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "GestorFinanceiro",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        // An xtool project should contain exactly one library product,
        // representing the main app.
        .library(
            name: "GestorFinanceiro",
            targets: ["GestorFinanceiro"]
        ),
    ],
    targets: [
        .target(
            name: "GestorFinanceiro"
        ),
    ],
    swiftLanguageModes: [.v5]
)
