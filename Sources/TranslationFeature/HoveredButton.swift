//
//  HoveredButton.swift
//  LLML
//
//  Created by Watanabe Toshinori on 2025/02/15.
//

import SwiftUI

struct HoveredButton<Label: View>: View {

    var label: Label

    var action: () -> Void

    @State private var isHovered: Bool = false

    init(action: @escaping () -> Void, @ViewBuilder label: () -> Label) {
        self.action = action
        self.label = label()
    }

    var body: some View {
        Button(action: action) {
            label
        }
        .buttonStyle(.link)
        .foregroundStyle(.primary)
        .background(isHovered ? Color(NSColor.unemphasizedSelectedContentBackgroundColor) : Color.clear)
        .cornerRadius(8)
        .onHover { isHovered in
            self.isHovered = isHovered
        }
    }
}
