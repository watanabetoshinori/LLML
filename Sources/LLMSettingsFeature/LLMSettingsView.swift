//
//  LLMSettingsViewModel.swift
//  LLML
//
//  Created by Watanabe Toshinori on 2025/02/15.
//

import AppSettingsClient
import AppleTranslateClient
import Observation
import OllamaClient
import OpenAIClient
import SettingsItem
import SwiftUI

@MainActor
@Observable
public class LLMSettingsViewModel {

    // Properties

    private(set) var translationProvider: TranslationProvider = .openAI

    private(set) var openAIAPIKey = ""

    private(set) var ollamaURL = ""

    private(set) var ollamaModel = ""

    @ObservationIgnored
    private var translationProviderObservationTask: Task<Void, Never>?

    @ObservationIgnored
    private var openAIAPIKeyObservationTask: Task<Void, Never>?

    @ObservationIgnored
    private var ollamaURLObservationTask: Task<Void, Never>?

    @ObservationIgnored
    private var ollamaModelObservationTask: Task<Void, Never>?

    // Clients

    @ObservationIgnored
    private var appSettingsClient: AppSettingsClient

    @ObservationIgnored
    private var openAIClient: OpenAIClient

    @ObservationIgnored
    private var ollamaClient: OllamaClient

    @ObservationIgnored
    private var appleTranslateClient: AppleTranslateClient

    // Initializing

    public init(
        appSettingsClient: AppSettingsClient = .liveValue,
        openAIClient: OpenAIClient = .liveValue,
        ollamaClient: OllamaClient = .liveValue,
        appleTranslateClient: AppleTranslateClient = .liveValue
    ) {
        self.appSettingsClient = appSettingsClient
        self.openAIClient = openAIClient
        self.ollamaClient = ollamaClient
        self.appleTranslateClient = appleTranslateClient

        // Observes status updates from Client
        translationProviderObservationTask = Task {
            for await value in appSettingsClient.translationProvider() {
                translationProvider = TranslationProvider(rawValue: value.rawValue) ?? .openAI
            }
        }

        openAIAPIKeyObservationTask = Task {
            for await value in openAIClient.apiKey() {
                openAIAPIKey = value
            }
        }

        ollamaURLObservationTask = Task {
            for await value in ollamaClient.url() {
                ollamaURL = value
            }
        }

        ollamaModelObservationTask = Task {
            for await value in ollamaClient.model() {
                ollamaModel = value
            }
        }
    }

    // Actions

    func openAISwitchDidChange(_ newValue: Bool) {
        guard newValue else { return }

        Task {
            await appSettingsClient.setTranslationProvider(.openAI)
        }
    }

    func ollamaSwitchDidChange(_ newValue: Bool) {
        guard newValue else { return }
        Task {
            await appSettingsClient.setTranslationProvider(.ollama)
        }
    }

    func openAIAPIKeyTextFieldDidChange(_ newValue: String) {
        Task {
            await openAIClient.setAPIKey(newValue)
        }
    }

    func ollamaURLTextFieldDidChange(_ newValue: String) {
        Task {
            await ollamaClient.setURL(newValue)
        }
    }

    func ollamaModelTextFieldDidChange(_ newValue: String) {
        Task {
            await ollamaClient.setModel(newValue)
        }
    }

    func appleTranslateSwitchDidChange(_ newValue: Bool) {
        guard newValue else { return }

        Task {
            await appSettingsClient.setTranslationProvider(.appleTranslate)
        }
    }
}

public struct LLMSettingsView: View {

    @Bindable var viewModel: LLMSettingsViewModel

    public init(viewModel: LLMSettingsViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                SettingsItem(title: "LLM") {
                    openAI
                    ollama
                    if #available(macOS 15.0, *) {
                        appleTranslate
                    }
                }
            }
        }
    }

    private var openAI: some View {
        VStack(alignment: .leading, spacing: 0) {
            Toggle(
                "OpenAI",
                isOn: Binding(get: { viewModel.translationProvider == .openAI },
                              set: { viewModel.openAISwitchDidChange($0) })
            )
            .toggleStyle(.checkbox)
            .padding(.bottom)

            GroupBox {
                HStack {
                    Text("API Key:")
                        .fontWeight(.semibold)
                    Spacer()
                    TextField(
                        "Enter your OpenAI API Key",
                        text: Binding(get: { viewModel.openAIAPIKey },
                                      set: { viewModel.openAIAPIKeyTextFieldDidChange($0) })
                    )
                    .textFieldStyle(.plain)
                    .multilineTextAlignment(.trailing)
                }
                .padding(4)
            }

            // Instructions for obtaining the OpenAI API key
            Group {
                Text(#"1. Visit [OpenAI Platform](https://platform.openai.com/) and log in or sign up."#)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(#"2. Generate an API key under "View API keys" and copy it."#)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(#"3. Paste the key into the above field."#)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)
        }
        .padding()
        .background(Color(NSColor.unemphasizedSelectedTextBackgroundColor).opacity(0.3))
        .cornerRadius(6)
        .overlay(
            // Highlight box for active selection
            RoundedRectangle(cornerRadius: 6)
                .stroke(viewModel.translationProvider == .openAI ? Color.blue : Color.primary.opacity(0.3), lineWidth: 0.5)
        )
    }

    private var ollama: some View {
        VStack(alignment: .leading, spacing: 0) {
            Toggle(
                "Ollama",
                isOn: Binding(get: { viewModel.translationProvider == .ollama },
                              set: { viewModel.ollamaSwitchDidChange($0) })
            )
            .toggleStyle(.checkbox)
            .padding(.bottom)

            GroupBox {
                VStack {
                    HStack {
                        Text("URL:")
                            .fontWeight(.semibold)
                        Spacer()
                        TextField(
                            "http://localhost:11434",
                            text: Binding(get: { viewModel.ollamaURL },
                                          set: { viewModel.ollamaURLTextFieldDidChange($0) })
                        )
                        .textFieldStyle(.plain)
                        .multilineTextAlignment(.trailing)
                    }
                    Divider()
                    HStack {
                        Text("Model:")
                            .fontWeight(.semibold)
                        Spacer()
                        TextField(
                            "llama3.1",
                            text: Binding(get: { viewModel.ollamaModel },
                                          set: { viewModel.ollamaModelTextFieldDidChange($0) })
                        )
                        .textFieldStyle(.plain)
                        .multilineTextAlignment(.trailing)
                    }
                }
                .padding(4)
            }
        }
        .padding()
        .background(Color(NSColor.unemphasizedSelectedTextBackgroundColor).opacity(0.3))
        .cornerRadius(6)
        .overlay(
            // Highlight box for active selection
            RoundedRectangle(cornerRadius: 6)
                .stroke(viewModel.translationProvider == .ollama ? Color.blue : Color.primary.opacity(0.3), lineWidth: 0.5)
        )
    }

    private var appleTranslate: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Toggle(
                    "Apple Translate",
                    isOn: Binding(get: { viewModel.translationProvider == .appleTranslate },
                                  set: { viewModel.appleTranslateSwitchDidChange($0) })
                )
                .toggleStyle(.checkbox)
                .padding(.bottom)
                Spacer()
            }

            Group {
                Text(
                    #"Apple Translate downloads the required model during the initial invocation and performs translations locally on the device afterward. The supported languages are limited."#
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 8)
        }
        .padding()
        .background(Color(NSColor.unemphasizedSelectedTextBackgroundColor).opacity(0.3))
        .cornerRadius(6)
        .overlay(
            // Highlight box for active selection
            RoundedRectangle(cornerRadius: 6)
                .stroke(viewModel.translationProvider == .appleTranslate ? Color.blue : Color.primary.opacity(0.3), lineWidth: 0.5)
        )
    }
}
