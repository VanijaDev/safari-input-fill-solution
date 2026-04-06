//
//  FolderRowView.swift
//  FFill
//
//  Display row for a single Folder — name and item count.
//

import SwiftUI

struct FolderRowView: View {
    let folder: Folder

    var body: some View {
        HStack {
            Label(folder.name, systemImage: "folder")
            Spacer()
            Text("\(folder.items.count)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
    }
}
