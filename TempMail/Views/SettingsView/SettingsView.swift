//
//  SettingsView.swift
//  TempMail
//
//  Created by Rishi Singh on 02/05/25.
//

import SwiftUI


enum SettingPage {
    case importPage
    case exportPage
    case appIconPage
    case appColorPage
    case aboutPage
}


struct SettingsView: View {
    @StateObject private var settingsViewModel = SettingsViewModel()

    var body: some View {
#if os(macOS)
        MacOSSettings()
#elseif os(iOS)
        IOSSettings()
#endif
    }
    
#if os(macOS)
    @ViewBuilder
    func MacOSSettings() -> some View {
        NavigationSplitView {
            List(
                selection: Binding(get: {
                    settingsViewModel.selectedSetting
                }, set: { newValue in
                    DispatchQueue.main.async {
                        withAnimation {
                            settingsViewModel.selectedSetting = newValue
                        }
                    }
                })
            ) {
                NavigationLink(value: SettingPage.importPage) {
                    Label("Import Addresses", systemImage: "square.and.arrow.down")
                }
                NavigationLink(value: SettingPage.exportPage) {
                    Label("Export Addresses", systemImage: "square.and.arrow.up")
                }
                NavigationLink(value: SettingPage.appColorPage) {
                    Label("Change App Color", systemImage: "paintpalette")
                }
                
                NavigationLink(value: SettingPage.aboutPage) {
                    Label("About TempBox", systemImage: "info.circle")
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("Settings")
            .onChange(of: settingsViewModel.selectedSetting, { oldValue, newValue in
                settingsViewModel.handleNavigationChange(oldValue, newValue)
            })
            .toolbar {
                navigationToolbar
            }
        } detail: {
            switch settingsViewModel.selectedSetting {
            case .importPage:
                ImportAddressesView()
            case .exportPage:
                ExportAddressesView()
            case .appIconPage:
                AppIconView()
            case .appColorPage:
                AppColorView()
            case .aboutPage:
                AboutView()
            }
        }
        .frame(width: 700, height: 400)
    }
    
    var navigationToolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .navigation) {
            Button("Back", systemImage: "chevron.left") {
                settingsViewModel.goBack()
            }
            .disabled(settingsViewModel.backButtonDisabled)
            Button("Forward", systemImage: "chevron.right") {
                settingsViewModel.goForward()
            }
            .disabled(settingsViewModel.forwardBtnDisabled)
        }
    }

#endif
    
#if os(iOS)
    @ViewBuilder
    func IOSSettings() -> some View {
        NavigationView {
            List {
                Section {
                    NavigationLink {
                        Label("Import Addresses", systemImage: "square.and.arrow.down")
                    } label: {
                        ImportAddressesView()
                    }
                    NavigationLink {
                        Label("Export Addresses", systemImage: "square.and.arrow.up")
                    } label: {
                        ExportAddressesView()
                    }
                }
                
                Section {
                    NavigationLink {
                        Label("Change App Icon", systemImage: "command")
                    } label: {
                        AppIconView()
                    }
                    NavigationLink {
                        Label("Change App Color", systemImage: "paintpalette")
                    } label: {
                        AppColorView()
                    }
                }
                
                Section {
                    NavigationLink {
                        Label("About TempBox", systemImage: "info.circle")
                    } label: {
                        AboutView()
                    }
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("Settings")
        }
    }
#endif
}

#Preview {
    SettingsView()
        .environmentObject(AccountsController.shared)
        .environmentObject(AddressesViewModel.shared)
        .environmentObject(SettingsViewModel.shared)
}
