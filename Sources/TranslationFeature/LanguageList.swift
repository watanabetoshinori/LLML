//
//  LanguageList.swift
//  LLML
//
//  Created by Watanabe Toshinori on 2025/02/15.
//

import Language
import SwiftUI

struct LanguageList: View {
    var selectedLanguage: Language

    @Binding var hoverLanguage: Language?

    var languages: [Language]

    var action: (Language) -> Void

    var body: some View {
        VStack(spacing: 0) {
            ForEach(languages, id: \.self) { language in
                HStack(spacing: 0) {
                    if language == selectedLanguage {
                        Image(systemName: "checkmark")
                            .foregroundColor(.blue)
                            .frame(width: 20)
                    } else {
                        Rectangle()
                            .foregroundStyle(.clear)
                            .frame(width: 20)
                    }
                    Text(language.name)
                        .foregroundStyle(selectedLanguage == language ? .blue : .primary)
                        .fontWeight(selectedLanguage == language ? .semibold : .regular)
                    Spacer()
                }
                .frame(height: 36)
                .padding(8)
                .background(
                    language == hoverLanguage ? Color.gray.opacity(0.2) : Color.clear
                )
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets())
                .onHover { isHovering in
                    hoverLanguage = isHovering ? language : nil
                }
                .onTapGesture {
                    action(language)
                }
            }
            Spacer()
        }
    }
}
