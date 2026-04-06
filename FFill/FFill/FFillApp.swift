//
//  FFillApp.swift
//  FFill
//
//  SwiftUI App entry point. Replaces the template-generated AppDelegate + Storyboard.
//

import SwiftUI
import SwiftData

@main
struct FFillApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(SharedContainer.modelContainer)
    }
}
