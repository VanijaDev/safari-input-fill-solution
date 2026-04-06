//
//  ContentView.swift
//  FFill
//
//  Root view — NavigationSplitView with sidebar + detail.
//

import SwiftUI

enum SidebarSelection: String, Hashable {
    case formData = "Form Data"
    case folders = "Folders"
    case settings = "Settings"
}

struct ContentView: View {
    @State private var sidebarSelection: SidebarSelection? = .formData

    var body: some View {
        NavigationSplitView {
            SidebarView(selection: $sidebarSelection)
        } detail: {
            NavigationStack {
                switch sidebarSelection {
                case .formData:
                    FormDataListView()
                case .folders:
                    FolderListView()
                case .settings:
                    SettingsView()
                case .none:
                    Text("Select a section from the sidebar.")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(minWidth: 700, minHeight: 450)
    }
}

#Preview {
    ContentView()
}
