//
//  NSPasteboardItem+String.swift
//  LLML
//
//  Created by Watanabe Toshinori on 2025/02/15.
//

import AppKit

extension NSPasteboardItem {
    var string: String? {
        types
            .compactMap { type in
                let data = self.data(forType: type) ?? Data()
                switch type {
                case .string, .URL, .fileURL: return String(data: data, encoding: .utf8)
                case .rtf, .rtfd, .html: return NSAttributedString(rtf: data, documentAttributes: nil)?.string
                default: return nil
                }
            }
            .first
    }
}
