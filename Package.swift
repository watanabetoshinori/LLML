// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "LLML",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "TranslationFeature",
            targets: ["TranslationFeature"]),
        .library(
            name: "SettingsFeature",
            targets: ["SettingsFeature"]),
        .library(
            name: "MenuCommand",
            targets: ["MenuCommand"]),
    ],
    dependencies: [
        .package(url: "https://github.com/kevinhermawan/OllamaKit.git", from: "5.0.7"),
        .package(url: "https://github.com/MacPaw/OpenAI.git", from: "0.3.0"),
    ],
    targets: [
        .target(
            name: "TranslationFeature",
            dependencies: [
                "AccessibilityClient",
                "AppSettingsClient",
                "PasteboardClient",
                "OpenAIClient",
                "OllamaClient",
                "AppleTranslateClient",
            ]
        ),
        .target(
            name: "SettingsFeature",
            dependencies: [
                "SettingsItem",
                "GeneralSettingsFeature",
                "LLMSettingsFeature",
                "UsageSettingsFeature",
                "AdvancedSettingsFeature",
            ]
        ),
        .target(
            name: "SettingsItem"
        ),
        .target(
            name: "GeneralSettingsFeature",
            dependencies: [
                "SettingsItem",
                "AccessibilityClient",
                "AppSettingsClient",
            ]
        ),
        .target(
            name: "LLMSettingsFeature",
            dependencies: [
                "SettingsItem",
                "AppSettingsClient",
                "OpenAIClient",
                "OllamaClient",
                "AppleTranslateClient",
            ]
        ),
        .target(
            name: "UsageSettingsFeature",
            dependencies: [
                "SettingsItem",
                "OpenAIClient",
            ]
        ),
        .target(
            name: "AdvancedSettingsFeature",
            dependencies: [
                "AppSettingsClient"
            ]
        ),
        .target(
            name: "MenuCommand"
        ),
        .target(
            name: "AccessibilityClient"
        ),
        .target(
            name: "AppSettingsClient",
            dependencies: [
                "KeyValueStore"
            ]
        ),
        .target(
            name: "KeyValueStore"
        ),
        .target(
            name: "PasteboardClient"
        ),
        .target(
            name: "OpenAIClient",
            dependencies: [
                .product(name: "OpenAI", package: "OpenAI"),
                "KeyValueStore",
                "Language",
            ]
        ),
        .target(
            name: "OllamaClient",
            dependencies: [
                .product(name: "OllamaKit", package: "OllamaKit"),
                "KeyValueStore",
                "Language",
            ]
        ),
        .target(
            name: "AppleTranslateClient",
            dependencies: [
                "Language"
            ]
        ),
        .target(
            name: "Language"
        ),
    ]
)
