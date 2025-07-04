//
//  TempBoxApp.swift
//  TempBox
//
//  Created by Rishi Singh on 01/05/25.
//

import SwiftUI
import SwiftData

@main
struct TempBoxApp: App {
    @Environment(\.openWindow) var openWindow
    @StateObject private var addressesController = AddressesController()
    @StateObject private var addressViewModel = AddressesViewModel()
    @StateObject private var settingsViewModel = SettingsViewModel()
    @StateObject private var appController = AppController()
    @StateObject private var messageDetailController = MessageDetailViewModel()
    @StateObject private var messagesViewModel = MessagesViewModel()
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Address.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, migrationPlan: AddressMigrationPlan.self, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(addressesController)
                .environmentObject(addressViewModel)
                .environmentObject(settingsViewModel)
                .environmentObject(appController)
                .environmentObject(messageDetailController)
                .environmentObject(messagesViewModel)
        }
        .modelContainer(sharedModelContainer)
#if os(macOS)
        .commands {
            SidebarCommands()
            CommandGroup(replacing: .appSettings) {
                Button(action: {
                    openWindow(id: "settings")
                }, label: {
                    Text("Settings")
                })
                .keyboardShortcut(",", modifiers: [.command])
            }
        }
#endif
        
#if os(macOS)
        //
        //        Window("About TempBox", id: "about") {
        //            Text("About Temobox")
        //        }
        //        .defaultSize(width: 300, height: 720)
        //        .windowResizability(.contentSize)
        //        .windowStyle(.hiddenTitleBar)
        
        Window("Settings", id: "settings") {
            SettingsView()
                .environmentObject(addressesController)
                .environmentObject(addressViewModel)
                .environmentObject(settingsViewModel)
        }
        .defaultSize(width: 700, height: 400)
        .windowResizability(.contentSize)
        .windowStyle(.titleBar)
#endif
    }
}
