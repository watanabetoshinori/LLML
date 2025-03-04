//
//  AlertMessageView.swift
//  LLML
//
//  Created by Watanabe Toshinori on 2025/02/15.
//

import SwiftUI

struct AlertMessageView: View {
    enum AlertType {
        case error
        case settings
    }

    var type: AlertType

    var message: String

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.white, .yellow)
                .font(.title2)
            Text(message)
                .font(.body)
                .foregroundColor(.primary)

            if type == .settings {
                SettingsLink {
                    Text("Fix")
                }
                .foregroundStyle(.primary)
                .cornerRadius(4)
                .padding(.horizontal)
            }
        }
        .padding(8)
        .background(type == .error ? Color.red.opacity(0.8) : Color(NSColor.unemphasizedSelectedTextBackgroundColor))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(type == .error ? Color.red : Color.primary.opacity(0.3), lineWidth: 0.5)
        )
    }
}
