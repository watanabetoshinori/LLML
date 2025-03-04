//
//  SettingsItem.swift
//  LLML
//
//  Created by Watanabe Toshinori on 2025/02/15.
//

import SwiftUI

public struct SettingsItem<Content: View>: View {

    var title: String

    var content: Content

    public init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    public var body: some View {
        Group {
            HStack {
                VStack {
                    HStack {
                        Spacer()
                        Text("\(title):")
                    }
                    Spacer()
                }
                .frame(width: 200)

                VStack(alignment: .leading) {
                    content
                    Spacer()
                }
                Spacer()
            }
        }
    }
}
