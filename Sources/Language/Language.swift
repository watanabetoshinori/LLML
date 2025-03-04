//
//  Language.swift
//  LLML
//
//  Created by Watanabe Toshinori on 2025/01/23.
//

import AppKit

public enum Language: String, Sendable, CaseIterable {
    case automatic
    case arabic
    case bulgarian
    case chinese_simplified
    case chinese_traditional
    case czech
    case danish
    case dutch
    case english_american
    case english_british
    case estonian
    case french
    case german
    case greek
    case hindi
    case hungarian
    case indonesian
    case italian
    case japanese
    case korean
    case latvian
    case lithuanian
    case norwegian_bokmål
    case polish
    case portuguese_brazilian
    case romanian
    case russian
    case slovak
    case slovenian
    case spanish
    case swedish
    case thai
    case turkish
    case ukrainian
    case vietnamese
    case none

    public var name: String {
        switch self {
        case .automatic: "Detect language"
        case .arabic: "Arabic"
        case .bulgarian: "Bulgarian"
        case .chinese_simplified: "Chinese (simplified)"
        case .chinese_traditional: "Chinese (traditional)"
        case .czech: "Czech"
        case .danish: "Danish"
        case .dutch: "Dutch"
        case .english_american: "English (American)"
        case .english_british: "English (British)"
        case .estonian: "Estonian"
        case .french: "French"
        case .german: "German"
        case .greek: "Greek"
        case .hindi: "Hindi"
        case .hungarian: "Hungarian"
        case .indonesian: "Indonesian"
        case .italian: "Italian"
        case .japanese: "Japanese"
        case .korean: "Korean"
        case .latvian: "Latvian"
        case .lithuanian: "Lithuanian"
        case .norwegian_bokmål: "Norwegian (bokmål)"
        case .polish: "Polish"
        case .portuguese_brazilian: "Portuguese (Brazilian)"
        case .romanian: "Romanian"
        case .russian: "Russian"
        case .slovak: "Slovak"
        case .slovenian: "Slovenian"
        case .spanish: "Spanish"
        case .swedish: "Swedish"
        case .thai: "Thai"
        case .turkish: "Turkish"
        case .ukrainian: "Ukrainian"
        case .vietnamese: "Vietnamese"
        case .none: ""
        }
    }

    public var identifier: String {
        switch self {
        case .automatic: "Automatic"
        case .arabic: "ar-AE"
        case .bulgarian: ""
        case .chinese_simplified: "zh-CN"
        case .chinese_traditional: "zh-TW"
        case .czech: ""
        case .danish: ""
        case .dutch: "nl-NL"
        case .english_american: "en-US"
        case .english_british: "en-GB"
        case .estonian: ""
        case .french: "fr-FR"
        case .german: "de-DE"
        case .greek: ""
        case .hindi: "hi-IN"
        case .hungarian: ""
        case .indonesian: "id-ID"
        case .italian: "it-IT"
        case .japanese: "ja-JP"
        case .korean: "ko-KR"
        case .latvian: ""
        case .lithuanian: ""
        case .norwegian_bokmål: ""
        case .polish: "pl-PL"
        case .portuguese_brazilian: "pt-BR"
        case .romanian: ""
        case .russian: "ru-RU"
        case .slovak: ""
        case .slovenian: ""
        case .spanish: "es-ES"
        case .swedish: ""
        case .thai: "th-TH"
        case .turkish: "tr-TR"
        case .ukrainian: "uk-UA"
        case .vietnamese: "vi-VN"
        case .none: ""
        }
    }
}
