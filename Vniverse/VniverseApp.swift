//
//  VniverseApp.swift
//  Vniverse
//
//  Created by chii_magnus on 2025/1/28.
//

import SwiftUI
import SwiftData

@main
struct VniverseApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Document.self,
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false, // 持久化存储
            allowsSave: true
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    @State private var showSettings = false

    var body: some Scene {
        WindowGroup {
            ContentView()
                .sheet(isPresented: $showSettings) {
                    SettingsView()
                }
        }
        .modelContainer(sharedModelContainer)
        .commands {
            CommandGroup(replacing: .appInfo) {
                EmptyView()
            }
            CommandMenu("设置") {
                Button("偏好设置...") {
                    showSettings.toggle()
                }
                .keyboardShortcut(",", modifiers: [.command])
            }
        }
    }
    
    init() {
        UserDefaults.standard.register(defaults: [
            "NSQuitAlwaysKeepsWindows": false
        ])
    }
}
