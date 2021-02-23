// swift-tools-version:5.4

import PackageDescription

let DXSample = Package(
  name: "DXSample",
  dependencies: [
    .package(name: "SwiftCOM", url: "http://github.com/compnerd/swift-com",
            .branch("main"))
  ],
  targets: [
    .executableTarget(
      name: "DXSample",
      dependencies: [
        .product(name: "SwiftCOM", package: "SwiftCOM"),
      ],
      resources: [
        .copy("Shaders"),
      ],
      swiftSettings: [
        .unsafeFlags([
          "-parse-as-library",
        ]),
      ],
      linkerSettings: [
        .linkedLibrary("User32"),
        .linkedLibrary("Ole32"),
      ]
    ),
  ]
)
