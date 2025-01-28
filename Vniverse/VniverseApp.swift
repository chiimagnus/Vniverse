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
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
