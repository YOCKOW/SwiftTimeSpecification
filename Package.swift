// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "TimeSpecification",
  products: [
    // Products define the executables and libraries produced by a package, and make them visible to other packages.
    .library(name: "SwiftTimeSpecification", type: .dynamic, targets: ["TimeSpecification"]),
  ],
  dependencies: [
    // Dependencies declare other packages that this package depends on.
  ],
  targets: [
    // Targets are the basic building blocks of a package. A target can define a module or a test suite.
    // Targets can depend on other targets in this package, and on products in packages which this package depends on.
    .target(name: "TimeSpecification", dependencies: []),
    .testTarget(name: "TimeSpecificationTests", dependencies: ["TimeSpecification"]),
  ],
  swiftLanguageVersions: [.v4, .v4_2, .v5]
)

