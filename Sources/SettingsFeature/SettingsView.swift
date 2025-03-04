//
//  SettingsView.swift
//  LLML
//
//  Created by Watanabe Toshinori on 2025/02/15.
//

import AdvancedSettingsFeature
import GeneralSettingsFeature
import LLMSettingsFeature
import SwiftUI
import UsageSettingsFeature

public struct SettingsView: View {

    public init() {}

    public var body: some View {
        TabView {
            GeneralSettingsView(viewModel: .init())
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            LLMSettingsView(viewModel: .init())
                .tabItem {
                    Label("LLM", systemImage: "atom")
                }

            UsageSettingsView(viewModel: .init())
                .tabItem {
                    Label("Usage", systemImage: "chart.bar.xaxis")
                }

            AdvancedSettingsView(viewModel: .init())
                .tabItem {
                    Label("Apps", systemImage: "lock.app.dashed")
                }
        }
        .scenePadding()
    }
}
