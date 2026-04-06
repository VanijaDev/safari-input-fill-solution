//
//  FormItemEditorView.swift
//  FFill
//
//  Sheet for adding or editing a FormItem.
//  Pass `item: nil` to create a new item, or an existing FormItem to edit it.
//

import SwiftUI
import SwiftData

struct FormItemEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Folder.sortOrder) private var folders: [Folder]

    let editingItem: FormItem?

    @State private var key: String
    @State private var value: String
    @State private var selectedFolderID: UUID?
    @State private var isRichText: Bool

    init(item: FormItem? = nil) {
        self.editingItem = item
        _key = State(initialValue: item?.key ?? "")
        _value = State(initialValue: item?.value ?? "")
        _selectedFolderID = State(initialValue: item?.folder?.id)
        _isRichText = State(initialValue: item?.isRichText ?? false)
    }

    private var isValid: Bool {
        !key.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        Form {
            Section("Item") {
                TextField("Key", text: $key)
                TextField("Value", text: $value, axis: .vertical)
                    .lineLimit(3...6)
            }

            Section("Organization") {
                Picker("Folder", selection: $selectedFolderID) {
                    Text("None").tag(Optional<UUID>.none)
                    ForEach(folders) { folder in
                        Text(folder.name).tag(Optional(folder.id))
                    }
                }
                Toggle("Rich Text", isOn: $isRichText)
            }
        }
        .formStyle(.grouped)
        .navigationTitle(editingItem == nil ? "New Item" : "Edit Item")
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
        let trimmedKey = key.trimmingCharacters(in: .whitespaces)
        let selectedFolder = folders.first { $0.id == selectedFolderID }

        if let item = editingItem {
            item.key = trimmedKey
            item.value = value
            item.folder = selectedFolder
            item.isRichText = isRichText
            item.updatedAt = Date()
        } else {
            let count = (try? context.fetchCount(FetchDescriptor<FormItem>())) ?? 0
            let newItem = FormItem(
                key: trimmedKey,
                value: value,
                sortOrder: count,
                isRichText: isRichText,
                folder: selectedFolder
            )
            context.insert(newItem)
        }
        dismiss()
    }
}
