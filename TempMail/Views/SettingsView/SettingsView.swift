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
    @EnvironmentObject private var settingsViewModel: SettingsViewModel
    
    var body: some View {
        Group {
#if os(macOS)
            MacOSSettings()
#elseif os(iOS)
            IOSSettings()
#endif
        }
        .alert("Error", isPresented: $settingsViewModel.showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(settingsViewModel.errorMessage)
        }
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
                        settingsViewModel.selectedSetting = newValue
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
        .frame(minWidth: 700, minHeight: 400)
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
                        ImportAddressesView()
                    } label: {
                        Label("Import Addresses", systemImage: "square.and.arrow.down")
                    }
                    NavigationLink {
                        ExportAddressesView()
                    } label: {
                        Label("Export Addresses", systemImage: "square.and.arrow.up")
                    }
                }

                Section {
                    NavigationLink {
                        AppIconView()
                    } label: {
                        Label("Change App Icon", systemImage: "command")
                    }
                    NavigationLink {
                        AppColorView()
                    } label: {
                        Label("Change App Color", systemImage: "paintpalette")
                    }
                }

                Section {
                    NavigationLink {
                        AboutView()
                    } label: {
                        Label("About TempBox", systemImage: "info.circle")
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
#endif
}

#Preview {
    SettingsView()
        .environmentObject(AddressesController.shared)
        .environmentObject(AddressesViewModel.shared)
        .environmentObject(SettingsViewModel.shared)
}
