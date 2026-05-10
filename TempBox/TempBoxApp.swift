//
//  TempBoxApp.swift
//  TempBox
//
//  Created by Rishi Singh on 01/05/25.
//

import SwiftUI
import SwiftData
import UserNotifications
#if os(iOS)
import BackgroundTasks
#endif

@main
struct TempBoxApp: App {
    var sharedModelContainer: ModelContainer

    @Environment(\.openWindow) var openWindow
    @Environment(\.scenePhase) private var scenePhase

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
    @StateObject private var networkMonitor: NetworkMonitor

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

        // Set notification delegate before the first notification can arrive
        UNUserNotificationCenter.current().delegate = NotificationService.shared

        #if os(iOS)
        BackgroundEmailService.register(modelContainer: container)
        #endif

        // Build the dependency graph
        let monitor = NetworkMonitor()
        _networkMonitor = StateObject(wrappedValue: monitor)
        let ctx = container.mainContext
        let networkService = MailTMNetworkService()
        let addressRepo = AddressRepository(modelContext: ctx)
        let messageRepo = MessageRepository(modelContext: ctx)
        let addressService = AddressService(repository: addressRepo, networkService: networkService)
        let messageService = MessageService(repository: messageRepo, networkService: networkService)

        _addressStore = State(initialValue: AddressStore(addressService: addressService, messageService: messageService, networkMonitor: monitor))
    }

    // MARK: - Lifecycle

    private func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .active:
            Task {
                let settings = await UNUserNotificationCenter.current().notificationSettings()
                guard settings.authorizationStatus == .authorized
                        || settings.authorizationStatus == .provisional else { return }
                LiveEmailPoller.shared.start(modelContext: sharedModelContainer.mainContext)
            }
        case .background:
            LiveEmailPoller.shared.stop()
            #if os(iOS)
            Task {
                let settings = await UNUserNotificationCenter.current().notificationSettings()
                guard settings.authorizationStatus == .authorized
                        || settings.authorizationStatus == .provisional else { return }
                BackgroundEmailService.scheduleBackgroundFetch()
            }
            #endif
        default:
            break
        }
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
                .environment(\.isNetworkConnected, networkMonitor.isConnected)
                .environment(\.connectionType, networkMonitor.connectionType)
                // Not migrated
                .environmentObject(iapManager)
                .environmentObject(webViewController)
                .environmentObject(remoteDataManager)
                .task {
                    await NotificationService.shared.requestPermission()
                }
                .onChange(of: scenePhase) { _, newPhase in
                    handleScenePhaseChange(newPhase)
                }
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
        NetworkMonitorCheckView()
            .accentColor(appStore.accentColor(colorScheme: colorScheme))
            .onAppear(perform: iapManager.initialize)
            .onAppear(perform: remoteDataManager.getRemoteData)
    }
}
