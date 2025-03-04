//
//  OpenAIClientError.swift
//  LLML
//
//  Created by Watanabe Toshinori on 2025/02/15.
//

import SwiftUI

public enum OpenAIClientError: Error, LocalizedError {
    case invalidSettings
    case promptingFailed
    case noTranslation

    public var errorDescription: String? {
        switch self {
        case .invalidSettings: "The OpenAI API key is missing."
        case .promptingFailed: "Failed to generate a valid prompt for the translation request."
        case .noTranslation: "The translation service did not return any result."
        }
    }
}
