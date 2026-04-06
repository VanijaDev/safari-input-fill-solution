//
//  SidebarView.swift
//  FFill
//

import SwiftUI

struct SidebarView: View {
    @Binding var selection: SidebarSelection?

    var body: some View {
        List(selection: $selection) {
            Label("Form Data", systemImage: "list.bullet.rectangle")
                .tag(SidebarSelection.formData)

            Label("Folders", systemImage: "folder")
                .tag(SidebarSelection.folders)

            Label("Settings", systemImage: "gear")
                .tag(SidebarSelection.settings)
        }
        .navigationTitle("FFill")
        .navigationSplitViewColumnWidth(min: 160, ideal: 200)
    }
}
