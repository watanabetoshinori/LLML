//
//  AppleTranslateClientError.swift
//  LLML
//
//  Created by Watanabe Toshinori on 2025/02/15.
//

import SwiftUI

public enum AppleTranslateClientError: Error, LocalizedError {
    case sessionNotAvailable
    case autoDetectionFailed
    case unsupportedLanguagePair
    case prepareTranslationFailed
    case translationFailed

    public var errorDescription: String? {
        switch self {
        case .sessionNotAvailable: "The Apple Translate session is not available."
        case .autoDetectionFailed: "Language auto-detection failed."
        case .unsupportedLanguagePair: "The specified language pair is not supported."
        case .prepareTranslationFailed: "Failed to prepare the translation request."
        case .translationFailed: "The translation operation failed."
        }
    }
}
