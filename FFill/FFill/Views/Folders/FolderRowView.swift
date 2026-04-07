//
//  FolderRowView.swift
//  FFill
//
//  Display row for a single Folder — name plus sub-folder and item counts.
//

import SwiftUI

struct FolderRowView: View {
    let folder: Folder

    /// Human-readable summary of direct contents: sub-folders, items, or both.
    private var contentSummary: String {
        let folderCount = folder.children.count
        let itemCount = folder.items.count
        switch (folderCount, itemCount) {
        case (0, 0):
            return ""
        case (let f, 0):
            return "\(f) \(f == 1 ? "sub-folder" : "sub-folders")"
        case (0, let i):
            return "\(i) \(i == 1 ? "item" : "items")"
        default:
            return "\(folderCount) \(folderCount == 1 ? "sub-folder" : "sub-folders"), \(itemCount) \(itemCount == 1 ? "item" : "items")"
        }
    }

    var body: some View {
        HStack {
            Label(folder.name, systemImage: "folder")
            Spacer()
            if !contentSummary.isEmpty {
                Text(contentSummary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
