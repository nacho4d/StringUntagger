// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "StringTagProcessor",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "StringTagProcessor",
            targets: ["StringTagProcessor"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/nacho4d/XCTestHTMLReport", .branch("xcode11_4_and_skipped_and_junit"))
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "StringTagProcessor",
            dependencies: []),
        .testTarget(
            name: "StringTagProcessorTests",
            dependencies: ["StringTagProcessor", "xchtmlreport"]),
    ]
)
