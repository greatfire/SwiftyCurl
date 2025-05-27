// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftyCurl",
    platforms: [.iOS(.v12), .macOS(.v12)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "SwiftyCurl",
            targets: ["SwiftyCurl"]),
    ],
    targets: [
        .binaryTarget(
            name: "CurlApple",
            url: "https://github.com/greatfire/curl-apple/releases/download/8.13.0/curl.xcframework.zip",
            // swift package compute-checksum curl.xcframework.zip
            checksum: "63c9923aae4a5dd6aaa5415bb78434b040a65634b3509f80c85fc0f16eb7f808"),
        .target(
            name: "SwiftyCurl",
            dependencies: ["CurlApple"],
            // Needed for CurlApple, but not allowed in `.binaryTarget`. Hrgrml. But works this way.
            linkerSettings: [
                .linkedLibrary("z"),
                .linkedLibrary("ldap", .when(platforms: [.macOS])),
                .linkedFramework("SystemConfiguration", .when(platforms: [.macOS]))]),
    ],
    swiftLanguageModes: [.v5]
)
