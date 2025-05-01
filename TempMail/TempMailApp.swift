//
//  TempMailApp.swift
//  TempMail
//
//  Created by Rishi Singh on 01/05/25.
//

import SwiftUI
import SwiftData

@main
struct TempMailApp: App {
    @StateObject private var accountsController = AccountsController()
    @StateObject private var addressViewModel = AddressesViewModel()
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Account.self,
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
                .environmentObject(accountsController)
                .environmentObject(addressViewModel)
        }
        .modelContainer(sharedModelContainer)
    }
}
