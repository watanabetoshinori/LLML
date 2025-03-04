//
//  KeyValueStore.swift
//  LLML
//
//  Created by Watanabe Toshinori on 2025/02/15.
//

import AppKit
import SwiftData

public actor KeyValueStore: ModelActor {
    public let modelContainer: ModelContainer

    public let modelExecutor: any ModelExecutor

    static public let liveValue = KeyValueStore()

    public init() {
        do {
            let appDirectoryURL = URL.applicationSupportDirectory.appendingPathComponent("LLML")
            do {
                try FileManager.default.createDirectory(at: appDirectoryURL, withIntermediateDirectories: true, attributes: nil)
            } catch {
                fatalError("Failed to create app directory: \(error)")
            }

            let url = appDirectoryURL.appendingPathComponent("keyvalue.store")
            let configuration = ModelConfiguration(url: url)
            modelContainer = try ModelContainer(for: KeyValue.self, configurations: configuration)
            modelExecutor = DefaultSerialModelExecutor(modelContext: ModelContext(modelContainer))
        } catch {
            fatalError("error create modelContainer: \(error)")
        }
    }

    public func get(_ key: String) -> String? {
        do {
            let predicate = #Predicate<KeyValue> { object in
                object.key == key
            }
            let descriptor = FetchDescriptor(predicate: predicate)
            return try modelContext.fetch(descriptor).first?.value
        } catch {
            print("Unable to retrieve the specified data.")
            return nil
        }
    }

    public func save(key: String, value: String) {
        do {
            let newModel = KeyValue(key: key, value: value)
            modelContext.insert(newModel)
            try modelContext.save()
        } catch {
            print("Unable to save the data.")
        }
    }
}
