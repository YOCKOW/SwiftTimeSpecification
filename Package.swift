// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "TimeSpecification",
  products: [.library(name: "SwiftTimeSpecification", type:.dynamic, targets: ["TimeSpecification"])],
  dependencies: [],
  targets: [
    .target(name: "TimeSpecification", dependencies: [], path:".", sources:["Sources"]),
    .testTarget(name: "TimeSpecificationTests", dependencies: ["TimeSpecification"])
  ],
  swiftLanguageVersions:[3, 4]
)
