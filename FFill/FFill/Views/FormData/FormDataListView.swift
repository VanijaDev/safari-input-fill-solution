//
//  FormDataListView.swift
//  FFill
//
//  Lists all FormItems with add, edit, and delete support.
//

import SwiftUI
import SwiftData

struct FormDataListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \FormItem.sortOrder) private var items: [FormItem]

    @State private var showingAddSheet = false
    @State private var itemToEdit: FormItem? = nil

    var body: some View {
        List {
            ForEach(items) { item in
                FormItemRowView(item: item)
                    .contextMenu {
                        Button("Edit") { itemToEdit = item }
                        Divider()
                        Button("Delete", role: .destructive) { context.delete(item) }
                    }
            }
            .onDelete(perform: deleteItems)
            .onMove(perform: moveItems)
        }
        .navigationTitle("Form Data")
        .overlay {
            if items.isEmpty {
                ContentUnavailableView(
                    "No Items",
                    systemImage: "list.bullet.rectangle",
                    description: Text("Add your first item using the + button.")
                )
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showingAddSheet = true } label: {
                    Label("Add Item", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            NavigationStack { FormItemEditorView() }
        }
        .sheet(item: $itemToEdit) { item in
            NavigationStack { FormItemEditorView(item: item) }
        }
    }

    private func deleteItems(at indexSet: IndexSet) {
        indexSet.forEach { context.delete(items[$0]) }
    }

    private func moveItems(from source: IndexSet, to destination: Int) {
        var reordered = items
        reordered.move(fromOffsets: source, toOffset: destination)
        for (index, item) in reordered.enumerated() {
            item.sortOrder = index
        }
    }
}
