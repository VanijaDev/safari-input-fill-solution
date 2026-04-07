//
//  FolderListView.swift
//  FFill
//
//  Lists all Folders with add, edit, delete, and drill-in to FolderDetailView.
//

import SwiftUI
import SwiftData

struct FolderListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Folder.sortOrder) private var folders: [Folder]

    @State private var showingAddSheet = false
    @State private var folderToEdit: Folder? = nil
    @State private var folderToDelete: Folder? = nil

    var body: some View {
        List {
            ForEach(folders) { folder in
                NavigationLink(value: folder) {
                    FolderRowView(folder: folder)
                }
                .contextMenu {
                    Button("Edit") { folderToEdit = folder }
                    Divider()
                    Button("Delete", role: .destructive) { folderToDelete = folder }
                }
            }
            .onDelete(perform: deleteFolders)
            .onMove(perform: moveFolders)
        }
        .navigationTitle("Folders")
        .navigationDestination(for: Folder.self) { folder in
            FolderDetailView(folder: folder)
        }
        .overlay {
            if folders.isEmpty {
                ContentUnavailableView(
                    "No Folders",
                    systemImage: "folder",
                    description: Text("Add your first folder using the + button.")
                )
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showingAddSheet = true } label: {
                    Label("Add Folder", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            NavigationStack { FolderEditorView() }
        }
        .sheet(item: $folderToEdit) { folder in
            NavigationStack { FolderEditorView(folder: folder) }
        }
        .alert("Delete \"\(folderToDelete?.name ?? "")\"?",
               isPresented: Binding(get: { folderToDelete != nil }, set: { if !$0 { folderToDelete = nil } })) {
            Button("Delete", role: .destructive) {
                if let folder = folderToDelete { context.delete(folder) }
                folderToDelete = nil
            }
            Button("Cancel", role: .cancel) { folderToDelete = nil }
        } message: {
            Text("Items in this folder will be unassigned, not deleted.")
        }
    }

    private func deleteFolders(at indexSet: IndexSet) {
        indexSet.forEach { context.delete(folders[$0]) }
    }

    private func moveFolders(from source: IndexSet, to destination: Int) {
        var reordered = folders
        reordered.move(fromOffsets: source, toOffset: destination)
        for (index, folder) in reordered.enumerated() {
            folder.sortOrder = index
        }
    }
}
