//
//  OllamaClientError.swift
//  LLML
//
//  Created by Watanabe Toshinori on 2025/02/15.
//

import SwiftUI

public enum OllamaClientError: Error, LocalizedError {
    case invalidSettings
    case noTranslation

    public var errorDescription: String? {
        switch self {
        case .invalidSettings: "The URL of the Ollama translation service is invalid."
        case .noTranslation: "The translation service did not return any result."
        }
    }
}
