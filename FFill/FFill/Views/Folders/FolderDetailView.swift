//
//  FolderDetailView.swift
//  FFill
//
//  Shows all items assigned to a specific folder, with edit and delete support.
//

import SwiftUI
import SwiftData

struct FolderDetailView: View {
    @Environment(\.modelContext) private var context
    let folder: Folder

    @State private var itemToEdit: FormItem? = nil

    private var sortedItems: [FormItem] {
        folder.items.sorted { $0.sortOrder < $1.sortOrder }
    }

    var body: some View {
        List {
            ForEach(sortedItems) { item in
                FormItemRowView(item: item)
                    .contextMenu {
                        Button("Edit") { itemToEdit = item }
                        Divider()
                        Button("Delete", role: .destructive) { context.delete(item) }
                    }
            }
            .onDelete(perform: deleteItems)
        }
        .navigationTitle(folder.name)
        .overlay {
            if sortedItems.isEmpty {
                ContentUnavailableView(
                    "No Items",
                    systemImage: "tray",
                    description: Text("Assign items to this folder from the Form Data list.")
                )
            }
        }
        .sheet(item: $itemToEdit) { item in
            NavigationStack { FormItemEditorView(item: item) }
        }
    }

    private func deleteItems(at indexSet: IndexSet) {
        indexSet.forEach { context.delete(sortedItems[$0]) }
    }
}
