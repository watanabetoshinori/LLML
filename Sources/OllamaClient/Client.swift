//
//  OllamaClient.swift
//  LLML
//
//  Created by Watanabe Toshinori on 2025/02/15.
//

import AppKit
@preconcurrency import Combine
import KeyValueStore
import Language
import OllamaKit

public struct OllamaClient: Sendable {
    public var url: @Sendable () -> AsyncPublisher<AnyPublisher<String, Never>>
    public var setURL: @Sendable (String) async -> Void
    public var model: @Sendable () -> AsyncPublisher<AnyPublisher<String, Never>>
    public var setModel: @Sendable (String) async -> Void
    public var translate: @Sendable (_ sourceLanguage: Language, _ targetLanguage: Language, _ sourceText: String) async throws -> String
}

extension OllamaClient {
    static public let liveValue = Self.live(dataStore: .liveValue)

    static func live(dataStore: KeyValueStore) -> Self {
        let keyOllamaURL = "ollamaURL"
        let keyOllamaModel = "ollamaModel"

        // Initialization of subjects for reactive data handling
        let urlSubject = CurrentValueSubject<String, Never>("")
        let modelSubject = CurrentValueSubject<String, Never>("")

        Task {
            let url = await dataStore.get(keyOllamaURL) ?? ""
            urlSubject.send(url)

            let model = await dataStore.get(keyOllamaModel) ?? ""
            modelSubject.send(model)
        }

        return Self(
            url: {
                urlSubject.eraseToAnyPublisher().values
            },
            setURL: { newValue in
                await dataStore.save(key: keyOllamaURL, value: newValue)
                urlSubject.send(newValue)
            },
            model: {
                modelSubject.eraseToAnyPublisher().values
            },
            setModel: { newValue in
                await dataStore.save(key: keyOllamaModel, value: newValue)
                modelSubject.send(newValue)
            },
            translate: { sourceLanguage, targetLanguage, sourceText in
                guard !sourceText.isEmpty else {
                    return ""
                }

                var prompt = "You are a professional translation engine. Translate the following message into \(targetLanguage.name). "
                if sourceLanguage == .automatic {
                    prompt += "The source language is automatically detected. "
                } else {
                    prompt += "The source language is \(sourceLanguage.name). "
                }
                prompt += "If the input is a single word, return up to three possible translations separated by commas. "
                prompt += "If the input is a sentence or longer text, return only the translated text without any additional explanation or comments. "
                prompt += ":\n\(sourceText)"

                // Validate settings
                var urlString = urlSubject.value.trimmingCharacters(in: .whitespaces)
                if urlString.isEmpty {
                    urlString = "http://localhost:11434"
                }
                guard let url = URL(string: urlString) else {
                    throw OllamaClientError.invalidSettings
                }
                var model = modelSubject.value.trimmingCharacters(in: .whitespaces)
                if model.isEmpty {
                    model = "llama3.1"
                }

                let ollamaKit = OllamaKit(baseURL: url)
                let messages: [OKChatRequestData.Message] = [.init(role: .system, content: prompt), .init(role: .user, content: sourceText)]
                var chatData = OKChatRequestData(model: model, messages: messages, tools: [])
                chatData.options = OKCompletionOptions(temperature: 0)

                // Extract the translated text from stream
                var translation = ""
                for try await response in ollamaKit.chat(data: chatData) {
                    translation += response.message?.content ?? ""
                }

                guard !translation.isEmpty else {
                    throw OllamaClientError.noTranslation
                }

                return translation
            }
        )
    }
}
