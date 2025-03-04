//
//  AdvancedSettingsView.swift
//  LargeL
//
//  Created by Watanabe Toshinori on 2025/02/15.
//

import AppSettingsClient
import Cocoa
import SwiftUI

@MainActor
@Observable
public class AdvancedSettingsViewModel {

    var excludedApps: [String] = []

    // Properties

    var selectedIndex: Int?

    // Clients

    @ObservationIgnored
    private var appSettingsClient: AppSettingsClient

    // Initializing

    public init(
        appSettingsClient: AppSettingsClient = .liveValue
    ) {
        self.appSettingsClient = appSettingsClient

        Task {
            excludedApps = await appSettingsClient.excludedApps()
        }
    }

    // Actions

    func rowSelected(_ index: Int) {
        selectedIndex = index
    }

    func plusTapped() {
        // Open a file dialog to retrieve the bundle ID and display name.
        let fileDialog = NSOpenPanel()
        fileDialog.prompt = "Select App"
        fileDialog.canChooseDirectories = false
        fileDialog.canChooseFiles = true
        fileDialog.allowedContentTypes = [.applicationBundle]
        fileDialog.treatsFilePackagesAsDirectories = false

        guard fileDialog.runModal() == .OK else {
            return
        }

        guard let selectedURL = fileDialog.url else {
            return
        }

        // Mac App
        let infoPlistURL = selectedURL.appendingPathComponent("Contents/Info.plist")
        if let plist = NSDictionary(contentsOf: infoPlistURL),
            let bundleIdentifier = plist["CFBundleIdentifier"] as? String
        {
            Task {
                await appSettingsClient.addExcludedApp(bundleIdentifier)
                excludedApps = await appSettingsClient.excludedApps()
            }
            return
        }

        // iOS app
        let wrappedInfoPlistURL = selectedURL.appendingPathComponent("WrappedBundle/Info.plist")
        if let plist = NSDictionary(contentsOf: wrappedInfoPlistURL),
            let bundleIdentifier = plist["CFBundleIdentifier"] as? String
        {
            Task {
                await appSettingsClient.addExcludedApp(bundleIdentifier)
                excludedApps = await appSettingsClient.excludedApps()
            }
            return
        }
    }

    func minusTapped() {
        guard let selectedIndex else {
            return
        }
        Task {
            let app = excludedApps[selectedIndex]
            await appSettingsClient.removeExcludedApp(app)
            excludedApps = await appSettingsClient.excludedApps()
            self.selectedIndex = nil
        }
    }

}

public struct AdvancedSettingsView: View {

    @Bindable var viewModel: AdvancedSettingsViewModel

    public init(viewModel: AdvancedSettingsViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("App will not propose translations in the following apps:")

            List {
                ForEach(Array(viewModel.excludedApps.enumerated()), id: \.offset) { index, app in
                    HStack {
                        icon(for: app)
                            .resizable()
                            .frame(width: 20, height: 20)
                            .padding(.trailing, 10)

                        Text(displayName(for: app))
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Spacer()
                    }
                    .padding(8)
                    .listRowBackground(index % 2 == 1
                                        ? Color(NSColor.windowBackgroundColor)
                                        : Color(NSColor.controlBackgroundColor))
                    .background(index == viewModel.selectedIndex ? Color.blue.opacity(0.3) : Color.clear)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.rowSelected(index)
                    }
                }
                .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
            .alternatingRowBackgrounds()
            .border(Color.gray, width: 1)

            HStack {
                Button(action: {
                    viewModel.plusTapped()
                }) {
                    Image(systemName: "plus")
                }
                Button(action: {
                    viewModel.minusTapped()
                }) {
                    Image(systemName: "minus")
                }
                Spacer()
            }
            .padding(.bottom, 30)

            Spacer()
        }
        .padding(.horizontal, 40)
    }

    private func displayName(for bundleIdentifier: String) -> String {
        if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier),
            let displayName = try? appURL.resourceValues(forKeys: [.localizedNameKey]).localizedName
        {
            return displayName
        }
        return bundleIdentifier
    }

    private func icon(for bundleIdentifier: String) -> Image {
        if let appPath = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier)?.path {
            return Image(nsImage: NSWorkspace.shared.icon(forFile: appPath))
        }
        return Image(systemName: "questionmark.app.dashed")
    }
}
