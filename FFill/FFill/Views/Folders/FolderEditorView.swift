//
//  FolderEditorView.swift
//  FFill
//
//  Sheet for adding or editing a Folder.
//  Pass `folder: nil` to create a new folder, or an existing Folder to edit it.
//

import SwiftUI
import SwiftData

struct FolderEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let editingFolder: Folder?

    @State private var name: String

    init(folder: Folder? = nil) {
        self.editingFolder = folder
        _name = State(initialValue: folder?.name ?? "")
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        Form {
            Section("Folder") {
                TextField("Name", text: $name)
            }
        }
        .formStyle(.grouped)
        .navigationTitle(editingFolder == nil ? "New Folder" : "Edit Folder")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save", action: save)
                    .disabled(!isValid)
            }
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)

        if let folder = editingFolder {
            folder.name = trimmedName
        } else {
            let count = (try? context.fetchCount(FetchDescriptor<Folder>())) ?? 0
            let newFolder = Folder(name: trimmedName, sortOrder: count)
            context.insert(newFolder)
        }
        dismiss()
    }
}
