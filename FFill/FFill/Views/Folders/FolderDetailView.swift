//
//  FolderDetailView.swift
//  FFill
//
//  Shows sub-folders and items assigned to a specific folder.
//  Sub-folders can be added, edited, deleted, and reordered.
//  Items can be edited, deleted, and reordered.
//

import SwiftUI
import SwiftData

struct FolderDetailView: View {
    @Environment(\.modelContext) private var context
    let folder: Folder

    @State private var showingAddSubfolder = false
    @State private var subfolderToEdit: Folder? = nil
    @State private var subfolderToDelete: Folder? = nil
    @State private var itemToEdit: FormItem? = nil
    @State private var itemToDelete: FormItem? = nil

    private var sortedChildren: [Folder] {
        folder.children.sorted { $0.sortOrder < $1.sortOrder }
    }

    private var sortedItems: [FormItem] {
        folder.items.sorted { $0.sortOrder < $1.sortOrder }
    }

    var body: some View {
        List {
            if !sortedChildren.isEmpty {
                Section("Sub-folders") {
                    ForEach(sortedChildren) { child in
                        NavigationLink(value: child) {
                            FolderRowView(folder: child)
                        }
                        .contextMenu {
                            Button("Edit") { subfolderToEdit = child }
                            Divider()
                            Button("Delete", role: .destructive) { subfolderToDelete = child }
                        }
                    }
                    .onDelete(perform: deleteChildren)
                    .onMove(perform: moveChildren)
                }
            }

            Section("Items") {
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
        }
        .navigationTitle(folder.name)
        .overlay {
            if sortedChildren.isEmpty && sortedItems.isEmpty {
                ContentUnavailableView(
                    "Empty Folder",
                    systemImage: "tray",
                    description: Text("Assign items here from the Form Data list, or add a sub-folder.")
                )
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showingAddSubfolder = true } label: {
                    Label("Add Sub-folder", systemImage: "folder.badge.plus")
                }
            }
        }
        .sheet(isPresented: $showingAddSubfolder) {
            NavigationStack { FolderEditorView(parentFolder: folder) }
        }
        .sheet(item: $subfolderToEdit) { child in
            NavigationStack { FolderEditorView(folder: child) }
        }
        .sheet(item: $itemToEdit) { item in
            NavigationStack { FormItemEditorView(item: item) }
        }
        .alert("Delete \"\(subfolderToDelete?.name ?? "")\"?",
               isPresented: Binding(get: { subfolderToDelete != nil }, set: { if !$0 { subfolderToDelete = nil } })) {
            Button("Delete", role: .destructive) {
                if let child = subfolderToDelete { context.delete(child) }
                subfolderToDelete = nil
            }
            Button("Cancel", role: .cancel) { subfolderToDelete = nil }
        } message: {
            Text("Items will be unassigned. Sub-folders will become top-level folders.")
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

    private func deleteChildren(at indexSet: IndexSet) {
        indexSet.forEach { context.delete(sortedChildren[$0]) }
    }

    private func moveChildren(from source: IndexSet, to destination: Int) {
        var reordered = sortedChildren
        reordered.move(fromOffsets: source, toOffset: destination)
        for (index, child) in reordered.enumerated() {
            child.sortOrder = index
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
