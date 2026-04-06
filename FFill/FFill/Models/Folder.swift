//
//  Folder.swift
//  FFill
//
//  SwiftData model representing a folder that groups FormItems.
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

    init(name: String, sortOrder: Int = 0) {
        self.id = UUID()
        self.name = name
        self.sortOrder = sortOrder
        self.createdAt = Date()
        self.items = []
    }
}
