//
//  FolderEditorView.swift
//  FFill
//
//  Sheet for adding or editing a Folder.
//  Pass `folder: nil` to create a new folder, or an existing Folder to edit it.
//  Pass `parentFolder` to pre-select a parent when creating a sub-folder from FolderDetailView.
//

import SwiftUI
import SwiftData

struct FolderEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Folder.sortOrder) private var allFolders: [Folder]

    let editingFolder: Folder?
    let initialParent: Folder?

    @State private var name: String
    @State private var selectedParentID: UUID?

    init(folder: Folder? = nil, parentFolder: Folder? = nil) {
        self.editingFolder = folder
        self.initialParent = parentFolder
        _name = State(initialValue: folder?.name ?? "")
        _selectedParentID = State(initialValue: folder?.parent?.id ?? parentFolder?.id)
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    /// All folders eligible to be the parent: excludes the folder being edited and all its descendants.
    private var availableParents: [Folder] {
        guard let editing = editingFolder else { return allFolders }
        let excluded: Set<UUID> = editing.descendantIDs().union([editing.id])
        return allFolders.filter { !excluded.contains($0.id) }
    }

    var body: some View {
        Form {
            Section("Folder") {
                TextField("Name", text: $name)
            }

            Section("Organization") {
                Picker("Parent Folder", selection: $selectedParentID) {
                    Text("None (top-level)").tag(Optional<UUID>.none)
                    ForEach(availableParents) { folder in
                        Text(folder.fullPath).tag(Optional(folder.id))
                    }
                }
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
        let selectedParent = allFolders.first { $0.id == selectedParentID }

        if let folder = editingFolder {
            folder.name = trimmedName
            folder.parent = selectedParent
        } else {
            let count = (try? context.fetchCount(FetchDescriptor<Folder>())) ?? 0
            let newFolder = Folder(name: trimmedName, sortOrder: count, parent: selectedParent)
            context.insert(newFolder)
        }
        dismiss()
    }
}
