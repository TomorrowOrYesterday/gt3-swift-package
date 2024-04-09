// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "gt3-swift-package",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v8)
    ],
    products: [
        .library(
            name: "gt3-swift-package",
            targets: ["GT3Captcha"]
        )
    ],
    dependencies: [],
    targets: [
        
//        .target(name: "GT3Exmaple",
//                dependencies: []
////                resources: [.copy("./Sources/PrivacyInfo.xcprivacy"),
//////                            .copy("./Sources/GT3Captcha.bundle")]
//               ),
        .binaryTarget(name: "GT3Captcha",
                      path: "./Sources/GT3Captcha.xcframework")
        
        
        
    ]
)
