//
//  FormItem.swift
//  FFill
//
//  SwiftData model representing a single key-value form entry.
//  Target membership: FFill (app) + FFill Extension
//

import Foundation
import SwiftData

@Model
final class FormItem {
    var id: UUID
    var key: String
    var value: String
    var sortOrder: Int
    var isRichText: Bool
    var createdAt: Date
    var updatedAt: Date

    /// Optional folder this item belongs to. Nullified (not deleted) when folder is removed.
    @Relationship(deleteRule: .nullify, inverse: \Folder.items)
    var folder: Folder?

    init(
        key: String,
        value: String,
        sortOrder: Int = 0,
        isRichText: Bool = false,
        folder: Folder? = nil
    ) {
        self.id = UUID()
        self.key = key
        self.value = value
        self.sortOrder = sortOrder
        self.isRichText = isRichText
        self.folder = folder
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
