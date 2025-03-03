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
    @AppStorage("appTheme") private var appTheme: AppTheme = .system

    var body: some Scene {
        WindowGroup {
            ContentView()
                .sheet(isPresented: $showSettings) {
                    SettingsView()
                }
                .preferredColorScheme(colorScheme)
        }
        .modelContainer(sharedModelContainer)
        .commands {
            // App Command Menu
            CommandGroup(replacing: .appInfo) {
                Button("关于 Vniverse") {
                    // TODO: 显示关于窗口
                }
                
                Divider()

                Button("偏好设置...") {
                    showSettings.toggle()
                }
                .keyboardShortcut(",", modifiers: [.command])
            }
            
            // File Command Menu
            CommandGroup(replacing: .newItem) {
                Button("导入文档...") {
                    NotificationCenter.default.post(name: Notification.Name("ImportDocument"), object: nil)
                }
                .keyboardShortcut("o", modifiers: [.command])
            }
            
            // Edit Command Menu
            TextEditingCommands()

            // Window Command Menu
            // CommandGroup(replacing: .windowList) {
            //     Button("最小化") {
            //         NSApplication.shared.keyWindow?.miniaturize(nil)
            //     }
            //     .keyboardShortcut("m", modifiers: [.command])
                
            //     Button("缩放") {
            //         NSApplication.shared.keyWindow?.zoom(nil)
            //     }
                
            //     Divider()
                
            //     Button("前置所有窗口") {
            //         NSApplication.shared.activate(ignoringOtherApps: true)
            //     }
            // }
            
            // Help Command Menu
            CommandGroup(replacing: .help) {
                Button("Vniverse 快捷键手册") {
                    // TODO: 显示帮助文档
                }
            }
        }
    }
    
    private var colorScheme: ColorScheme? {
        switch appTheme {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system:
            return nil
        }
    }
    
    init() {
        UserDefaults.standard.register(defaults: [
            "NSQuitAlwaysKeepsWindows": false
        ])
    }
}
