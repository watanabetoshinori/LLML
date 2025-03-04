//
//  KeyValue.swift
//  LLML
//
//  Created by Watanabe Toshinori on 2025/02/15.
//

import SwiftData

@Model
public final class KeyValue {
    @Attribute(.unique) var key: String

    var value: String

    public init(key: String, value: String) {
        self.key = key
        self.value = value
    }
}
