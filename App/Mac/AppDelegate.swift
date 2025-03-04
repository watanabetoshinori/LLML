//
//  AppDelegate.swift
//  LLML
//
//  Created by Watanabe Toshinori on 2025/02/15.
//

import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    var isTerminateFromMenu = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        NSApplication.shared.unhide(self)
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        guard sender.frameAutosaveName != "com_apple_SwiftUI_Settings_window" else { return true }
        // Prevents the window from closing and hides it instead
        NSApplication.shared.hide(self)
        return false
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        if isTerminateFromMenu {
            return .terminateNow
        }
        NSApplication.shared.hide(self)
        NSApp.setActivationPolicy(.accessory)
        return .terminateCancel
    }
}
