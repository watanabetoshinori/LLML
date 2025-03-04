//
//  GeneralSettingsViewModel.swift
//  LLML
//
//  Created by Watanabe Toshinori on 2025/02/15.
//

import AccessibilityClient
import AppSettingsClient
import Observation
import SettingsItem
import SwiftUI

@MainActor
@Observable
public class GeneralSettingsViewModel {
    enum AppLayout: String {
        case horizontal
        case vertical
    }

    // Properties

    private(set) var accessibilityEnabled = false

    private(set) var shortcutEnabled = false

    private(set) var startAtSystemStartup = false

    private(set) var appLayout: AppLayout = .horizontal

    private(set) var version = ""

    @ObservationIgnored
    private var accessibilityObservationTask: Task<Void, Never>?

    @ObservationIgnored
    private var shortcutEnabledObservationTask: Task<Void, Never>?

    @ObservationIgnored
    private var appLayoutObservationTask: Task<Void, Never>?

    // Clients

    @ObservationIgnored
    private var accessibilityClient: AccessibilityClient

    @ObservationIgnored
    private var appSettingsClient: AppSettingsClient

    // Initializing

    public init(
        accessibilityClient: AccessibilityClient = .liveValue,
        appSettingsClient: AppSettingsClient = .liveValue
    ) {
        self.accessibilityClient = accessibilityClient
        self.appSettingsClient = appSettingsClient

        // Observes status updates from Client
        accessibilityObservationTask = Task {
            for await value in accessibilityClient.statuses() {
                accessibilityEnabled = value
            }
        }

        shortcutEnabledObservationTask = Task {
            for await value in appSettingsClient.shortcutEnabled() {
                shortcutEnabled = value
            }
        }

        startAtSystemStartup = appSettingsClient.startAtSystemStartup()

        appLayoutObservationTask = Task {
            for await value in appSettingsClient.appLayout() {
                appLayout = AppLayout(rawValue: value.rawValue) ?? .horizontal
            }
        }

        version = appSettingsClient.version()
    }

    // Actions

    func openSecurityAndPrivacyButtonTapped() {
        if !accessibilityEnabled {
            accessibilityClient.request()
        } else {
            accessibilityClient.openSettings()
        }
    }

    func shortcutEnabledSwitchDidChange(_ newValue: Bool) {
        Task {
            await appSettingsClient.setShortcutEnabled(newValue)
        }
    }

    func startAtSystemStartupSwitchDidChange(_ newValue: Bool) {
        startAtSystemStartup = newValue
        do {
            try appSettingsClient.setStartAtSystemStartup(newValue)
        } catch {
            print(error)
        }
    }

    func horizontalLayoutSwitchDidChange(_ newValue: Bool) {
        guard newValue else { return }
        Task {
            await appSettingsClient.setAppLayout(.horizontal)
        }
    }

    func veriticalLayoutSwitchDidChange(_ newValue: Bool) {
        guard newValue else { return }
        Task {
            await appSettingsClient.setAppLayout(.vertical)
        }
    }

    func openGithubButtonTapped() {
        appSettingsClient.openSourceCodeSite()
    }
}

public struct GeneralSettingsView: View {

    @Bindable var viewModel: GeneralSettingsViewModel

    public init(viewModel: GeneralSettingsViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                SettingsItem(title: "App Permission") {
                    Text(viewModel.accessibilityEnabled ? "Enabled" : "Disabled")

                    Button("Open Security & Privacy") {
                        viewModel.openSecurityAndPrivacyButtonTapped()
                    }

                    Group {
                        Text("App Permission is required to enable the shortcut.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 8)
                }

                Divider()

                SettingsItem(title: "App Shortcut") {
                    Toggle("⌘+C+C",
                           isOn: Binding(get: { viewModel.shortcutEnabled },
                                         set: { viewModel.shortcutEnabledSwitchDidChange($0) })
                    )
                    .toggleStyle(.checkbox)
                    .disabled(!viewModel.accessibilityEnabled)
                }

                Divider()

                SettingsItem(title: "App start") {
                    Toggle("Start App at system startup",
                           isOn: Binding(get: { viewModel.startAtSystemStartup },
                                         set: { viewModel.startAtSystemStartupSwitchDidChange($0) })
                    )
                    .toggleStyle(.checkbox)
                }

                Divider()

                SettingsItem(title: "App Layout") {
                    HStack(spacing: 16) {
                        Button(action: {
                            viewModel.horizontalLayoutSwitchDidChange(true)
                        }) {
                            VStack {
                                Image(systemName: "rectangle.split.2x1")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 50, height: 50)
                                Text("Horizontal")
                            }
                            .padding()
                        }
                        .frame(width: 100)
                        .buttonStyle(.link)
                        .foregroundStyle(viewModel.appLayout == .horizontal ? Color.accentColor : Color.secondary)
                        .background(viewModel.appLayout == .horizontal ? Color(NSColor.unemphasizedSelectedContentBackgroundColor) : Color.clear)
                        .cornerRadius(8)

                        Button(action: {
                            viewModel.veriticalLayoutSwitchDidChange(true)
                        }) {
                            VStack {
                                Image(systemName: "rectangle.split.1x2")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 50, height: 50)
                                Text("Vertical")
                            }
                            .padding()
                        }
                        .frame(width: 100)
                        .buttonStyle(.link)
                        .foregroundStyle(viewModel.appLayout == .vertical ? Color.accentColor : Color.secondary)
                        .background(viewModel.appLayout == .vertical ? Color(NSColor.unemphasizedSelectedContentBackgroundColor) : Color.clear)
                        .cornerRadius(8)
                    }
                    .padding(.horizontal)
                }

                Divider()

                SettingsItem(title: "Version") {
                    Text(viewModel.version)

                    Button("Open GitHub") {
                        viewModel.openGithubButtonTapped()
                    }
                }
            }
        }
    }
}
