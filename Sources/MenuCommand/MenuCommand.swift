//
//  MenuCommand.swift
//  LLML
//
//  Created by Watanabe Toshinori on 2025/02/15.
//

import SwiftUI

public struct MenuCommand: View {
    var title: String

    var shortcutKey: Character

    var action: () -> Void

    public init(title: String, shortcutKey: Character, action: @escaping () -> Void) {
        self.title = title
        self.shortcutKey = shortcutKey
        self.action = action
    }

    public var body: some View {
        Button {
            action()
        } label: {
            HStack(spacing: 0) {
                Text(title)
                    .foregroundColor(.primary)
                Spacer()
                Text("⌘")
                    .foregroundColor(.primary)
                    .font(.system(size: 12))
                    .opacity(0.5)
                    .frame(width: 12)
                Text(shortcutKey.uppercased())
                    .foregroundColor(.primary)
                    .font(.system(size: 12))
                    .opacity(0.5)
                    .frame(width: 12)
            }
        }
        .buttonStyle(.plain)
        .keyboardShortcut(KeyEquivalent(shortcutKey), modifiers: [.command])
    }
}
