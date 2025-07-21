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
    @StateObject private var appController = AppController.shared
    @StateObject private var messageDetailController = MessageDetailViewModel()
    @StateObject private var messagesViewModel = MessagesViewModel()
    @StateObject private var iapManager = IAPManager()
    @StateObject private var webViewController = WebViewController()
    @StateObject private var remoteDataManager = RemoteDataManager()
    
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
            RootView()
                .environmentObject(addressesController)
                .environmentObject(addressViewModel)
                .environmentObject(settingsViewModel)
                .environmentObject(appController)
                .environmentObject(messageDetailController)
                .environmentObject(messagesViewModel)
                .environmentObject(iapManager)
                .environmentObject(webViewController)
                .environmentObject(remoteDataManager)
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
        Window("Settings", id: "settings") {
            SettingsView()
                .environmentObject(addressesController)
                .environmentObject(addressViewModel)
                .environmentObject(settingsViewModel)
                .environmentObject(appController)
                .environmentObject(remoteDataManager)
                .environmentObject(iapManager)
        }
        .defaultSize(width: 700, height: 400)
        .windowResizability(.contentSize)
        .windowStyle(.titleBar)
#endif
    }
}

struct RootView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject private var appController: AppController
    @EnvironmentObject private var iapManager: IAPManager
    @EnvironmentObject private var remoteDataManager: RemoteDataManager
    
    var body: some View {
        ContentView()
            .accentColor(appController.accentColor(colorScheme: colorScheme))
            .onAppear(perform: iapManager.initialize)
            .onAppear(perform: remoteDataManager.getRemoteData)
    }
}
