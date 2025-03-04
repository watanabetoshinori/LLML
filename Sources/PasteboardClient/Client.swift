//
//  PasteboardClient.swift
//  LLML
//
//  Created by Watanabe Toshinori on 2025/02/15.
//

import AppKit

public struct PasteboardItem: Sendable {
    public let bundleIdentifier: String
    public let string: String
}

public struct PasteboardClient: Sendable {
    public var values: @Sendable () -> AsyncStream<PasteboardItem> = { AsyncStream { _ in } }
}

extension PasteboardClient {
    static public let liveValue = Self(
        values: {
            AsyncStream { continuation in
                var previousTime: TimeInterval = 0

                // Sets up a global key event monitor for detecting `cmd + c` presses
                let event = MonitoringEvent(
                    NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
                        handleKeyDown(event: event, previousTime: &previousTime, continuation: continuation)
                    }
                )

                continuation.onTermination = { _ in
                    if let monitor = event.monitor {
                        NSEvent.removeMonitor(monitor)
                    }
                }
            }
        }
    )
}

private class MonitoringEvent: @unchecked Sendable {
    let monitor: Any?

    init(_ monitor: Any?) {
        self.monitor = monitor
    }
}

private func handleKeyDown(event: NSEvent, previousTime: inout TimeInterval, continuation: AsyncStream<PasteboardItem>.Continuation) {
    // Ensure the pressed key is `c` with the `command` modifier.
    guard event.modifierFlags.contains(.command), event.keyCode == 8 else { return }

    let currentTime = Date().timeIntervalSinceReferenceDate

    // Check if the time interval since the last event is within 1 second
    if previousTime > 0,
        Int((currentTime - previousTime) * 1_000) <= 1_000,
        let string = NSPasteboard.general.pasteboardItems?.first?.string?.trimmingCharacters(in: .whitespacesAndNewlines),
        !string.isEmpty
    {
        let newItem = PasteboardItem(
            bundleIdentifier: NSWorkspace.shared.frontmostApplication?.bundleIdentifier ?? "",
            string: string
        )
        continuation.yield(newItem)
    }

    previousTime = currentTime
}
