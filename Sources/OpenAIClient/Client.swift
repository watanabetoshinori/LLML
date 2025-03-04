//
//  OpenAIClient.swift
//  LLML
//
//  Created by Watanabe Toshinori on 2025/02/15.
//

import AppKit
@preconcurrency import Combine
import KeyValueStore
import Language
import OpenAI

public struct OpenAIClient: Sendable {
    public var apiKey: @Sendable () -> AsyncPublisher<AnyPublisher<String, Never>>
    public var setAPIKey: @Sendable (String) async -> Void
    public var inputTokenCount: @Sendable () -> AsyncPublisher<AnyPublisher<Int, Never>>
    public var outputTokenCount: @Sendable () -> AsyncPublisher<AnyPublisher<Int, Never>>
    public var resetTokenCount: @Sendable () async -> Void
    public var translate: @Sendable (_ sourceLanguage: Language, _ targetLanguage: Language, _ sourceText: String) async throws -> String
}

extension OpenAIClient {
    static public let liveValue = Self.live(dataStore: .liveValue)

    static func live(dataStore: KeyValueStore) -> Self {
        let keyOpenAIAPIKey = "openAIAPIKey"
        let keyOpenAIInputTokens = "openAIInputTokens"
        let keyOpenAIOutputTokens = "openAIOutputTokens"

        // Initialization of subjects for reactive data handling
        let apiKeySubject = CurrentValueSubject<String, Never>("")
        let inputTokenCountSubject = CurrentValueSubject<Int, Never>(0)
        let outputTokenCountSubject = CurrentValueSubject<Int, Never>(0)

        Task {
            let openAIAPIKey = await dataStore.get(keyOpenAIAPIKey) ?? ""
            apiKeySubject.send(openAIAPIKey)

            let openAIInputTokens = await Int(dataStore.get(keyOpenAIInputTokens) ?? "0") ?? 0
            inputTokenCountSubject.send(openAIInputTokens)

            let openAIOutputTokens = await Int(dataStore.get(keyOpenAIOutputTokens) ?? "0") ?? 0
            outputTokenCountSubject.send(openAIOutputTokens)
        }

        return Self(
            apiKey: {
                apiKeySubject.eraseToAnyPublisher().values
            },
            setAPIKey: { newValue in
                await dataStore.save(key: keyOpenAIAPIKey, value: newValue)
                apiKeySubject.send(newValue)
            },
            inputTokenCount: {
                inputTokenCountSubject.eraseToAnyPublisher().values
            },
            outputTokenCount: {
                outputTokenCountSubject.eraseToAnyPublisher().values
            },
            resetTokenCount: {
                await dataStore.save(key: keyOpenAIInputTokens, value: String("0"))
                await dataStore.save(key: keyOpenAIOutputTokens, value: String("0"))

                inputTokenCountSubject.send(0)
                outputTokenCountSubject.send(0)
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
                let apiKey = apiKeySubject.value.trimmingCharacters(in: .whitespaces)
                guard !apiKey.isEmpty else {
                    throw OpenAIClientError.invalidSettings
                }

                guard let message = ChatQuery.ChatCompletionMessageParam(role: .user, content: prompt) else {
                    throw OpenAIClientError.promptingFailed
                }

                let query = ChatQuery(
                    messages: [message],
                    model: .gpt4_o_mini,
                    frequencyPenalty: 1,
                    presencePenalty: 1,
                    temperature: 0
                )

                let openAI = OpenAI(apiToken: apiKey)
                let result = try await openAI.chats(query: query)

                // Update token usage count
                let inputTokenCount = inputTokenCountSubject.value
                let outputTokenCount = outputTokenCountSubject.value
                let newInputTokenCount = inputTokenCount + (result.usage?.promptTokens ?? 0)
                let newOutputTokenCount = outputTokenCount + (result.usage?.completionTokens ?? 0)

                await dataStore.save(key: keyOpenAIInputTokens, value: String(newInputTokenCount))
                await dataStore.save(key: keyOpenAIOutputTokens, value: String(newOutputTokenCount))

                inputTokenCountSubject.send(newInputTokenCount)
                outputTokenCountSubject.send(newOutputTokenCount)

                // Extract the translated text
                guard let translation = result.choices.first?.message.content?.string else {
                    throw OpenAIClientError.noTranslation
                }

                return translation
            }
        )
    }
}
