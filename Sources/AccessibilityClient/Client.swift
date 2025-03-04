//
//  AccessibilityClient.swift
//  LLML
//
//  Created by Watanabe Toshinori on 2025/02/15.
//

@preconcurrency import AppKit

public struct AccessibilityClient: Sendable {
    public var request: @Sendable () -> Void
    public var statuses: @Sendable () -> AsyncStream<Bool>
    public var openSettings: @Sendable () -> Void
}

extension AccessibilityClient {
    static public let liveValue = Self(
        request: {
            // Prompts the user to grant accessibility permissions for the app
            AXIsProcessTrustedWithOptions(
                [
                    kAXTrustedCheckOptionPrompt.takeRetainedValue() as NSString: true
                ] as CFDictionary
            )
        },
        statuses: {
            AsyncStream { continuation in
                let task = Task {
                    // Initial check for accessibility permissions
                    let isTrusted = AXIsProcessTrusted()
                    continuation.yield(isTrusted)

                    // Monitor changes to accessibility permissions using distributed notifications
                    let osNotifications = DistributedNotificationCenter.default().notifications(
                        named: NSNotification.Name("com.apple.accessibility.api")
                    )

                    for await notification in osNotifications {
                        let isTrusted = AXIsProcessTrusted()
                        continuation.yield(isTrusted)
                    }
                }
                continuation.onTermination = { _ in
                    task.cancel()
                }
            }
        },
        openSettings: {
            // Opens the Accessibility settings page in System Preferences
            guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else { return }
            NSWorkspace.shared.open(url)
        }
    )
}
