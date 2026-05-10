//
//  NetworkMonitorCheckView.swift
//  TempBox
//
//  Created by Rishi Singh on 23/04/26.
//

import SwiftUI
import SwiftData

struct NetworkMonitorCheckView: View {
    @Environment(\.isNetworkConnected) private var isConnected
    @State private var userDismissed: Bool = false

    private var sheetBinding: Binding<Bool> {
        Binding(
            get: { !(isConnected ?? true) && !userDismissed },
            set: { if !$0 { userDismissed = true } }
        )
    }

    var body: some View {
        AppUpdateCheckView()
            .sheet(isPresented: sheetBinding) {
                NetworkMonitorView()
                    .presentationDetents([.height(310)])
            }
            .onChange(of: isConnected) { _, newValue in
                if newValue == false {
                    userDismissed = false
                }
            }
    }
}

#Preview {
    let schema = Schema([Address.self, Folder.self])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [config])
    let ctx = container.mainContext
    let networkService = MailTMNetworkService()
    let addressRepo = AddressRepository(modelContext: ctx)
    let messageRepo = MessageRepository(modelContext: ctx)
    let addressService = AddressService(repository: addressRepo, networkService: networkService)
    let messageService = MessageService(repository: messageRepo, networkService: networkService)
    let addressStore = AddressStore(addressService: addressService, messageService: messageService, networkMonitor: NetworkMonitor())

    NetworkMonitorCheckView()
        .environment(addressStore)
        .environment(AppStore())
        .environment(AddressesViewModel())
        .environment(SettingsViewModel())
        .environment(MessagesViewModel())
        .environment(MessageDetailViewModel())
        .environmentObject(WebViewController())
        .environmentObject(IAPManager())
        .environmentObject(RemoteDataManager())
        .environmentObject(NetworkMonitor())
        .environment(\.isNetworkConnected, false)
        .modelContainer(container)
}
