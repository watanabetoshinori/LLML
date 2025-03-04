//
//  AppSettingsClient.swift
//  LLML
//
//  Created by Watanabe Toshinori on 2025/02/15.
//

import AppKit
@preconcurrency import Combine
import KeyValueStore
import ServiceManagement

public enum TranslationProvider: String, Sendable {
    case openAI = "OpenAI"
    case ollama = "Ollama"
    case appleTranslate = "Apple Translate"
}

public enum AppLayout: String, Sendable {
    case horizontal
    case vertical
}

public struct AppSettingsClient: Sendable {
    public var shortcutEnabled: @Sendable () -> AsyncPublisher<AnyPublisher<Bool, Never>>
    public var setShortcutEnabled: @Sendable (Bool) async -> Void
    public var startAtSystemStartup: @Sendable () -> Bool
    public var setStartAtSystemStartup: @Sendable (Bool) throws -> Void
    public var version: @Sendable () -> String
    public var openSourceCodeSite: @Sendable () -> Void
    public var translationProvider: @Sendable () -> AsyncPublisher<AnyPublisher<TranslationProvider, Never>>
    public var setTranslationProvider: @Sendable (TranslationProvider) async -> Void
    public var appLayout: @Sendable () -> AsyncPublisher<AnyPublisher<AppLayout, Never>>
    public var setAppLayout: @Sendable (AppLayout) async -> Void
    public var sourceLanguage: @Sendable () -> AsyncPublisher<AnyPublisher<String, Never>>
    public var setSourceLanguage: @Sendable (String) async -> Void
    public var targetLanguage: @Sendable () -> AsyncPublisher<AnyPublisher<String, Never>>
    public var setTargetLanguage: @Sendable (String) async -> Void
    public var appWindowMakeActive: @Sendable () async -> Void
    public var autoExecuteTranslation: @Sendable () -> AsyncPublisher<AnyPublisher<Bool, Never>>
    public var setAutoExecuteTranslation: @Sendable (Bool) async -> Void
    public var excludedApps: @Sendable () async -> [String]
    public var addExcludedApp: @Sendable (String) async -> Void
    public var removeExcludedApp: @Sendable (String) async -> Void
}

extension AppSettingsClient {
    static public let liveValue = Self.live(dataStore: .liveValue)

    static func live(dataStore: KeyValueStore) -> Self {
        let keyShortcutEnabled = "shortcutEnabled"
        let keyTranslationProvider = "translationProvider"
        let keyAppLayout = "appLayout"
        let keySourceLanguage = "sourceLanguage"
        let keyTargetLanguage = "targetLanguage"
        let keyAutoExecuteTranslation = "autoExecuteTranslation"
        let keyExcludedApps = "excludedApps"

        let sourceCodeRepositoryURL = "https://github.com/watanabe-toshinori/LargeL"

        // Initialization of subjects for reactive data handling
        let shortcutEnabledSubject = CurrentValueSubject<Bool, Never>(false)
        let translationProviderSubject = CurrentValueSubject<TranslationProvider, Never>(.openAI)
        let appLayoutSubject = CurrentValueSubject<AppLayout, Never>(.horizontal)
        let sourceLanguageSubject = CurrentValueSubject<String, Never>("")
        let targetLanguageSubject = CurrentValueSubject<String, Never>("")
        let autoExecuteTranslationSubject = CurrentValueSubject<Bool, Never>(true)

        Task {
            let shortcutEnabled = await dataStore.get(keyShortcutEnabled)
            shortcutEnabledSubject.send(shortcutEnabled == "true")

            let translationProvider = await dataStore.get(keyTranslationProvider) ?? ""
            translationProviderSubject.send(TranslationProvider(rawValue: translationProvider) ?? .openAI)

            let appLayout = await dataStore.get(keyAppLayout) ?? ""
            appLayoutSubject.send(AppLayout(rawValue: appLayout) ?? .horizontal)

            let sourceLanguage = await dataStore.get(keySourceLanguage) ?? "English (American)"
            sourceLanguageSubject.send(sourceLanguage)

            let targetLanguage = await dataStore.get(keyTargetLanguage) ?? "English (American)"
            targetLanguageSubject.send(targetLanguage)

            let autoExecuteTranslation = await dataStore.get(keyAutoExecuteTranslation) ?? "true"
            autoExecuteTranslationSubject.send(autoExecuteTranslation == "true")
        }

        return Self(
            shortcutEnabled: {
                shortcutEnabledSubject.eraseToAnyPublisher().values
            },
            setShortcutEnabled: { newValue in
                let value = newValue ? "true" : "false"
                await dataStore.save(key: keyShortcutEnabled, value: value)
                shortcutEnabledSubject.send(value == "true")
            },
            startAtSystemStartup: {
                SMAppService.mainApp.status == .enabled
            },
            setStartAtSystemStartup: { isEnabled in
                if isEnabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            },
            version: {
                Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
            },
            openSourceCodeSite: {
                guard let url = URL(string: sourceCodeRepositoryURL) else { return }
                NSWorkspace.shared.open(url)
            },
            translationProvider: {
                translationProviderSubject.eraseToAnyPublisher().values
            },
            setTranslationProvider: { newValue in
                await dataStore.save(key: keyTranslationProvider, value: newValue.rawValue)
                translationProviderSubject.send(newValue)
            },
            appLayout: {
                appLayoutSubject.eraseToAnyPublisher().values
            },
            setAppLayout: { newValue in
                await dataStore.save(key: keyAppLayout, value: newValue.rawValue)
                appLayoutSubject.send(newValue)
            },
            sourceLanguage: {
                sourceLanguageSubject.eraseToAnyPublisher().values
            },
            setSourceLanguage: { newValue in
                await dataStore.save(key: keySourceLanguage, value: newValue)
                sourceLanguageSubject.send(newValue)
            },
            targetLanguage: {
                targetLanguageSubject.eraseToAnyPublisher().values
            },
            setTargetLanguage: { newValue in
                await dataStore.save(key: keyTargetLanguage, value: newValue)
                targetLanguageSubject.send(newValue)
            },
            appWindowMakeActive: {
                do {
                    // Delay to ensure the app window can be activated.
                    try await Task.sleep(nanoseconds: 250_000_000)  // 0.25sec
                    await NSApp.activate(ignoringOtherApps: true)
                } catch {
                    print("Failed to activate the application window due to an unexpected error.")
                }
            },
            autoExecuteTranslation: {
                autoExecuteTranslationSubject.eraseToAnyPublisher().values
            },
            setAutoExecuteTranslation: { newValue in
                let value = newValue ? "true" : "false"
                await dataStore.save(key: keyAutoExecuteTranslation, value: value)
                autoExecuteTranslationSubject.send(value == "true")
            },
            excludedApps: {
                guard let value = await dataStore.get(keyExcludedApps) else {
                    return []
                }
                do {
                    return try JSONDecoder().decode([String].self, from: Data(value.utf8))
                } catch {
                    return []
                }
            },
            addExcludedApp: { app in
                var newApps = [app]
                if let value = await dataStore.get(keyExcludedApps),
                    let apps = try? JSONDecoder().decode([String].self, from: Data(value.utf8))
                {
                    newApps += apps
                }

                if let data = try? JSONEncoder().encode(newApps), let value = String(data: data, encoding: .utf8) {
                    await dataStore.save(key: keyExcludedApps, value: value)
                }
            },
            removeExcludedApp: { app in
                if let value = await dataStore.get(keyExcludedApps),
                    var apps = try? JSONDecoder().decode([String].self, from: Data(value.utf8))
                {
                    apps.removeAll(where: { $0 == app })
                    if let data = try? JSONEncoder().encode(apps), let value = String(data: data, encoding: .utf8) {
                        await dataStore.save(key: keyExcludedApps, value: value)
                    }
                }
            }
        )
    }
}
