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

    var body: some View {
        List {
            ForEach(folders) { folder in
                NavigationLink(value: folder) {
                    FolderRowView(folder: folder)
                }
                .contextMenu {
                    Button("Edit") { folderToEdit = folder }
                    Divider()
                    Button("Delete", role: .destructive) { context.delete(folder) }
                }
            }
            .onDelete(perform: deleteFolders)
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
    }

    private func deleteFolders(at indexSet: IndexSet) {
        indexSet.forEach { context.delete(folders[$0]) }
    }
}
