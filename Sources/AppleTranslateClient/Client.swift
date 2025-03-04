//
//  AppleTranslateClient.swift
//  LLML
//
//  Created by Watanabe Toshinori on 2025/02/15.
//

import AppKit
@preconcurrency import Combine
import Language
#if canImport(Translation)
@preconcurrency import Translation
#endif

public struct AppleTranslateClient: Sendable {
    public var configuration: @Sendable () -> AsyncPublisher<AnyPublisher<AppleTranslateConfiguration, Never>>
    public var updateLanguages: @Sendable (_ sourceLanguage: Language, _ targetLanguage: Language) -> Void
    public var setSession: @Sendable (_ session: AppleTranslateSession) async -> Void
    public var translate: @Sendable (_ sourceLanguage: Language, _ targetLanguage: Language, _ sourceText: String) async throws -> String
}

extension AppleTranslateClient {
    static public let liveValue: Self = {
        if #available(macOS 15.0, *) {
            return Self.live()
        } else {
            return Self.mock()
        }
    }()

    static func mock() -> Self {
        Self(
            configuration: { Just(.init(rawValue: "Undefined")).eraseToAnyPublisher().values },
            updateLanguages: { _, _ in fatalError("macOS 15.0 is required") },
            setSession: { _ in fatalError("macOS 15.0 is required") },
            translate: { _, _, _ in fatalError("macOS 15.0 is required") }
        )
    }

    @available(macOS 15.0, *)
    static func live() -> Self {
        let sessionManager = TranslationSessionManager()

        // Initialization of subjects for reactive data handling
        let configurationSubject = CurrentValueSubject<AppleTranslateConfiguration, Never>(.init(rawValue: TranslationSession.Configuration()))

        return Self(
            configuration: {
                configurationSubject.eraseToAnyPublisher().values
            },
            updateLanguages: { sourceLanguage, targetLanguage in
                let newConfiguration: TranslationSession.Configuration
                if !sourceLanguage.identifier.isEmpty, sourceLanguage.identifier != "Automatic" {
                    newConfiguration = .init(source: .init(identifier: sourceLanguage.identifier), target: .init(identifier: targetLanguage.identifier))
                } else {
                    newConfiguration = .init(target: .init(identifier: targetLanguage.identifier))
                }
                configurationSubject.send(.init(rawValue: newConfiguration))
            },
            setSession: { newValue in
                await sessionManager.setSession(newValue.translationSession)
            },
            translate: { sourceLanguage, targetLanguage, sourceText in
                guard !sourceText.isEmpty else {
                    return ""
                }

                guard let session = await sessionManager.translationSession else {
                    throw AppleTranslateClientError.sessionNotAvailable
                }

                let availability = LanguageAvailability()
                let status: LanguageAvailability.Status

                if let sourceLanguage = session.sourceLanguage {
                    status = await availability.status(
                        from: sourceLanguage,
                        to: session.targetLanguage
                    )
                } else {
                    do {
                        status = try await availability.status(
                            for: sourceText,
                            to: session.targetLanguage
                        )
                    } catch {
                        print(error)
                        throw AppleTranslateClientError.autoDetectionFailed
                    }
                }

                switch status {
                case .installed:
                    do {
                        let response = try await session.translate(sourceText)
                        return response.targetText
                    } catch {
                        print(error)
                        throw AppleTranslateClientError.translationFailed
                    }
                case .supported:
                    do {
                        try await session.prepareTranslation()
                        return ""
                    } catch {
                        print(error)
                        throw AppleTranslateClientError.prepareTranslationFailed
                    }
                case .unsupported:
                    throw AppleTranslateClientError.unsupportedLanguagePair
                @unknown default:
                    return ""
                }
            }
        )
    }
}

public struct AppleTranslateConfiguration: @unchecked Sendable {
    let rawValue: Any

    @available(macOS 15.0, *)
    public var translationSessionConfiguration: TranslationSession.Configuration {
        rawValue as! TranslationSession.Configuration
    }

    public init(rawValue: Any) {
        self.rawValue = rawValue
    }
}

public struct AppleTranslateSession: @unchecked Sendable {
    let rawValue: Any

    @available(macOS 15.0, *)
    public var translationSession: TranslationSession {
        rawValue as! TranslationSession
    }

    public init(rawValue: Any) {
        self.rawValue = rawValue
    }
}

@available(macOS 15.0, *)
actor TranslationSessionManager {
    private(set) var translationSession: TranslationSession?

    func setSession(_ newValue: TranslationSession) {
        translationSession = newValue
    }
}
