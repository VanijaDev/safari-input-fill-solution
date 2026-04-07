//
//  Folder.swift
//  FFill
//
//  SwiftData model representing a folder that groups FormItems.
//  Folders support nesting — a folder can have an optional parent and multiple children.
//  Target membership: FFill (app) + FFill Extension
//

import Foundation
import SwiftData

@Model
final class Folder {
    var id: UUID
    var name: String
    var sortOrder: Int
    var createdAt: Date

    /// Items assigned to this folder. Deleting a folder nullifies items' folder reference.
    @Relationship(deleteRule: .nullify)
    var items: [FormItem]

    /// Optional parent folder. When the parent is deleted this folder becomes root-level (parent = nil).
    var parent: Folder?

    /// Child folders nested inside this folder. When this folder is deleted, children become root-level.
    @Relationship(deleteRule: .nullify, inverse: \Folder.parent)
    var children: [Folder]

    init(name: String, sortOrder: Int = 0, parent: Folder? = nil) {
        self.id = UUID()
        self.name = name
        self.sortOrder = sortOrder
        self.createdAt = Date()
        self.items = []
        self.children = []
        self.parent = parent
    }

    /// Full path from root to this folder, e.g. "Work / Engineering".
    var fullPath: String {
        if let parent {
            return "\(parent.fullPath) / \(name)"
        }
        return name
    }

    /// Recursively collects all descendant folder IDs (children, grandchildren, …).
    /// Used to prevent cycles when picking a parent folder.
    func descendantIDs() -> Set<UUID> {
        var result = Set<UUID>()
        for child in children {
            result.insert(child.id)
            result.formUnion(child.descendantIDs())
        }
        return result
    }
}
