// swift-tools-version: 5.8

import PackageDescription

let package = Package(
  name: "ScannerUIKit",
  platforms: [
    .iOS(.v11)
  ],
  products: [
    .library(name: "ScannerUIKit", targets: ["ScannerUIKit"])
  ],
  dependencies: [
    .package(url: "https://github.com/sereivoanyong/EmptyUIKit", branch: "main")
  ],
  targets: [
    .target(name: "ScannerUIKit", dependencies: ["EmptyUIKit"])
  ]
)
