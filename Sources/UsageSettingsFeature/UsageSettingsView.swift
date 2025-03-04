//
//  UsageSettingsView.swift
//  LLML
//
//  Created by Watanabe Toshinori on 2025/02/15.
//

import Observation
import OpenAIClient
import SettingsItem
import SwiftUI

@MainActor
@Observable
public class UsageSettingsViewModel {

    // Properties

    private(set) var inputTokens = ""

    private(set) var outputTokens = ""

    @ObservationIgnored
    private var inputTokensObservationTask: Task<Void, Never>?

    @ObservationIgnored
    private var outputTokensObservationTask: Task<Void, Never>?

    // Clients

    @ObservationIgnored
    private var openAIClient: OpenAIClient

    // Initializing

    public init(
        openAIClient: OpenAIClient = .liveValue
    ) {
        self.openAIClient = openAIClient

        // Observes status updates from Client
        inputTokensObservationTask = Task {
            for await value in openAIClient.inputTokenCount() {
                inputTokens = convertDisplayableTokens(value)
            }
        }

        outputTokensObservationTask = Task {
            for await value in openAIClient.outputTokenCount() {
                outputTokens = convertDisplayableTokens(value)
            }
        }
    }

    // Actions

    func resetButtonDidTapped() {
        Task {
            await openAIClient.resetTokenCount()
        }
    }

    // Helpers

    private func convertDisplayableTokens(_ tokens: Int) -> String {
        // Converts token count into a user-friendly format including millions
        if tokens == 0 {
            return "0 (0.00 M)"
        } else {
            let millionDivider = 1_000_000.0
            let tokensInMillions = Double(tokens) / millionDivider
            return String(format: "%d (%.2f M)", tokens, tokensInMillions)
        }
    }
}

public struct UsageSettingsView: View {

    @Bindable var viewModel: UsageSettingsViewModel

    public init(viewModel: UsageSettingsViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                SettingsItem(title: "OpenAI API") {
                    GroupBox {
                        VStack {
                            HStack {
                                Text("Input Tokens:")
                                    .fontWeight(.semibold)
                                Spacer()
                                Text(viewModel.inputTokens)
                                    .foregroundStyle(.secondary)
                            }

                            Divider()

                            HStack {
                                Text("Output Tokens:")
                                    .fontWeight(.semibold)
                                Spacer()
                                Text(viewModel.outputTokens)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(4)
                    }
                    .padding(.horizontal)

                    GroupBox {
                        HStack {
                            Text("Reset Tokens Count")
                            Spacer()
                            Button("Reset") {
                                viewModel.resetButtonDidTapped()
                            }
                        }
                        .padding(4)
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
        }
    }
}
