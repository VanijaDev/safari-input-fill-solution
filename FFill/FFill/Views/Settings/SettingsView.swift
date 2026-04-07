//
//  SettingsView.swift
//  FFill
//
//  Settings placeholder. No additional settings are currently planned.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var items: [FormItem]
    @Query private var folders: [Folder]

    @State private var showingDeleteConfirmation = false

    var body: some View {
        Form {
            Section("Data") {
                Button("Delete All Data", role: .destructive) {
                    showingDeleteConfirmation = true
                }
                .disabled(items.isEmpty && folders.isEmpty)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Settings")
        .alert("Delete All Data?", isPresented: $showingDeleteConfirmation) {
            Button("Delete All", role: .destructive) { deleteAllData() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will permanently delete all \(items.count) item(s) and \(folders.count) folder(s). This action cannot be undone.")
        }
    }

    private func deleteAllData() {
        items.forEach { context.delete($0) }
        folders.forEach { context.delete($0) }
    }
}
