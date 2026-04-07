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
    @State private var itemToDelete: FormItem? = nil

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
                        Button("Delete", role: .destructive) { itemToDelete = item }
                    }
            }
            .onDelete(perform: deleteItems)
            .onMove(perform: moveItems)
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
        .alert("Delete \"\(itemToDelete?.key ?? "")\"?",
               isPresented: Binding(get: { itemToDelete != nil }, set: { if !$0 { itemToDelete = nil } })) {
            Button("Delete", role: .destructive) {
                if let item = itemToDelete { context.delete(item) }
                itemToDelete = nil
            }
            Button("Cancel", role: .cancel) { itemToDelete = nil }
        } message: {
            Text("This action cannot be undone.")
        }
    }

    private func deleteItems(at indexSet: IndexSet) {
        indexSet.forEach { context.delete(sortedItems[$0]) }
    }

    private func moveItems(from source: IndexSet, to destination: Int) {
        var reordered = sortedItems
        reordered.move(fromOffsets: source, toOffset: destination)
        for (index, item) in reordered.enumerated() {
            item.sortOrder = index
        }
    }
}
