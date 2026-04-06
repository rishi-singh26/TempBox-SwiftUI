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
    var sharedModelContainer: ModelContainer

    @Environment(\.openWindow) var openWindow

    // Migrated to @Observable → @State
    @State private var addressStore: AddressStore
    @State private var appStore = AppStore()
    @State private var addressesViewModel = AddressesViewModel()
    @State private var settingsViewModel = SettingsViewModel()
    @State private var messagesViewModel = MessagesViewModel()
    @State private var messageDetailViewModel = MessageDetailViewModel()

    // NOT migrated — remain @StateObject / @EnvironmentObject
    @StateObject private var iapManager = IAPManager()
    @StateObject private var webViewController = WebViewController()
    @StateObject private var remoteDataManager = RemoteDataManager()

    init() {
        let container: ModelContainer
        do {
            let schema = Schema([
                Address.self,
                Folder.self,
            ])
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            container = try ModelContainer(for: schema, migrationPlan: AddressMigrationPlan.self, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }

        self.sharedModelContainer = container

        // Build the dependency graph
        let ctx = container.mainContext
        let networkService = MailTMNetworkService()
        let addressRepo = AddressRepository(modelContext: ctx)
        let messageRepo = MessageRepository(modelContext: ctx)
        let addressService = AddressService(repository: addressRepo, networkService: networkService)
        let messageService = MessageService(repository: messageRepo, networkService: networkService)

        _addressStore = State(initialValue: AddressStore(addressService: addressService, messageService: messageService))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                // Migrated
                .environment(addressStore)
                .environment(appStore)
                .environment(addressesViewModel)
                .environment(settingsViewModel)
                .environment(messagesViewModel)
                .environment(messageDetailViewModel)
                // Not migrated
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
                .environment(addressStore)
                .environment(appStore)
                .environment(addressesViewModel)
                .environment(settingsViewModel)
                .environmentObject(remoteDataManager)
                .environmentObject(iapManager)
        }
        .defaultSize(width: 700, height: 400)
        .windowResizability(.contentSize)
        .windowStyle(.titleBar)
        .modelContainer(sharedModelContainer)
#endif
    }
}

struct RootView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(AppStore.self) private var appStore
    @EnvironmentObject private var iapManager: IAPManager
    @EnvironmentObject private var remoteDataManager: RemoteDataManager

    var body: some View {
        ContentView()
            .accentColor(appStore.accentColor(colorScheme: colorScheme))
            .onAppear(perform: iapManager.initialize)
            .onAppear(perform: remoteDataManager.getRemoteData)
    }
}
