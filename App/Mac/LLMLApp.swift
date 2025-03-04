//
//  LLMLApp.swift
//  LLML
//
//  Created by Watanabe Toshinori on 2025/02/15.
//

import MenuCommand
import SettingsFeature
import SwiftUI
import TranslationFeature

@main
struct LargeLApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Main window configuration
        WindowGroup {
            TranslationView(viewModel: .init())
                .background(.thickMaterial)
                .ignoresSafeArea()
                .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { notification in
                    guard let window = notification.object as? NSWindow else { return }
                    window.backgroundColor = NSColor.clear
                    window.delegate = appDelegate
                }
        }
        .defaultSize(width: 800, height: 600)
        .windowResizability(.contentSize)
        .windowStyle(.hiddenTitleBar)
        // .restorationBehavior(.disabled)

        // Settings window configuration
        Settings {
            SettingsView()
                .background(.thickMaterial)
        }
        .defaultSize(width: 700, height: 560)

        // Menu bar configuration
        MenuBarExtra("LLML", image: "MenuIcon") {
            VStack(spacing: 6) {
                MenuCommand(title: "Translate Text", shortcutKey: "1") {
                    NSApp.activate(ignoringOtherApps: true)
                }
                MenuCommand(title: "Quit", shortcutKey: "q") {
                    appDelegate.isTerminateFromMenu = true
                    NSApplication.shared.terminate(nil)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .frame(width: 216)
        }
        .menuBarExtraStyle(.window)
    }
}
