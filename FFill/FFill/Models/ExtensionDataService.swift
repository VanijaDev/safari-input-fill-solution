//
//  ExtensionDataService.swift
//  FFill / FFill Extension (dual target membership required)
//
//  Serializes SwiftData models into a JSON-compatible dictionary for the
//  Safari Web Extension native messaging protocol.
//
//  Extracted from SafariWebExtensionHandler so the logic can be unit-tested
//  from FFillTests without importing the Extension target (which pulls in
//  SafariServices and cannot be @testable-imported by a plain test target).
//

import Foundation
import SwiftData

enum ExtensionDataService {

    /// Fetches all FormItems and Folders from the given container and builds
    /// the JSON-serializable response payload.
    ///
    /// - Parameter container: The ModelContainer to query. Pass `nil` to use
    ///   the shared App Group container (production). Pass an in-memory
    ///   container in unit tests.
    /// - Returns: `["items": [...], "folders": [...]]` ready for JSON encoding.
    static func buildResponsePayload(using container: ModelContainer? = nil) throws -> [String: Any] {
        let resolvedContainer = container ?? SharedContainer.modelContainer
        let context = ModelContext(resolvedContainer)

        let items = try context.fetch(FetchDescriptor<FormItem>(sortBy: [SortDescriptor(\.sortOrder)]))
        let folders = try context.fetch(FetchDescriptor<Folder>(sortBy: [SortDescriptor(\.sortOrder)]))

        let itemsJSON: [[String: Any]] = items.map { item in
            var dict: [String: Any] = [
                "id": item.id.uuidString,
                "key": item.key,
                "value": item.value,
                "sortOrder": item.sortOrder
            ]
            // Omit folderId entirely when unassigned — JS treats undefined as falsy
            if let folderID = item.folder?.id.uuidString {
                dict["folderId"] = folderID
            }
            return dict
        }

        let foldersJSON: [[String: Any]] = folders.map { folder in
            let sortedItems = folder.items.sorted { $0.sortOrder < $1.sortOrder }
            return [
                "id": folder.id.uuidString,
                "name": folder.name,
                "sortOrder": folder.sortOrder,
                "itemIds": sortedItems.map { $0.id.uuidString }
            ]
        }

        return [
            "items": itemsJSON,
            "folders": foldersJSON
        ]
    }
}
