//
//  SharedContainer.swift
//  FFill
//
//  Provides the shared ModelContainer used by both the FFill app and FFill Extension.
//  Uses an explicit file URL inside the App Group container so both targets
//  read and write the same SwiftData store.
//  Target membership: FFill (app) + FFill Extension
//

import Foundation
import SwiftData

enum SharedContainer {
    /// The shared ModelContainer instance. Crashes on misconfiguration (missing App Group entitlement).
    static let modelContainer: ModelContainer = {
        let schema = Schema([FormItem.self, Folder.self])

        guard let groupURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: Constants.appGroupID
        ) else {
            fatalError("App Group '\(Constants.appGroupID)' not found. Check entitlements.")
        }

        let storeURL = groupURL.appendingPathComponent(Constants.storeFileName)
        let config = ModelConfiguration(schema: schema, url: storeURL)

        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()
}
