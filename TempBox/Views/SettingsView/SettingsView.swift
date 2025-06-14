//
//  SettingsView.swift
//  TempBox
//
//  Created by Rishi Singh on 02/05/25.
//

import SwiftUI


enum SettingPage {
    case importPage
    case exportPage
    case appIconPage
    case appColorPage
    case archive
    case aboutPage
}


struct SettingsView: View {
    @EnvironmentObject private var addressesController: AddressesController
    @EnvironmentObject private var settingsViewModel: SettingsViewModel
    
    @Environment(\.openURL) var openURL
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        Group {
#if os(macOS)
            MacOSSettings()
#elseif os(iOS)
            IOSSettings()
#endif
        }
        .alert("Alert", isPresented: $settingsViewModel.showArchAddrDeleteConf, actions: {
            Button("Cancel", role: .cancel) {}
            Button("Yes", role: .destructive) {
                Task {
                    await deleteArchivedAddresses()
                }
            }
        }, message: {
            Text("Are you sure you want to delete selected address\(settingsViewModel.selectedArchivedAddresses.count < 2 ? "" : "s")? This action is irreversible. Ones deleted, this address and the associated messages can not be restored.")
        })
        .alert("Open Link?", isPresented: $settingsViewModel.showLinkOpenConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Open", role: .destructive) {
                if let url = URL(string: settingsViewModel.linkToOpen) {
                    openURL(url)
                }
            }
        } message: {
            Text(settingsViewModel.linkToOpen)
        }
        .alert("Alert", isPresented: $settingsViewModel.showErrorAlert) {
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
                        withAnimation(.linear(duration: 0.2)) {
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
                NavigationLink(value: SettingPage.archive) {
                    Label("Archived Addresses", systemImage: "archivebox")
                }
                
                Text("")
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
                EmptyView()
            case .appColorPage:
                AppColorView()
            case .archive:
                ArchiveView()
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
                        ArchiveView()
                    } label: {
                        Label("Archived Addresses", systemImage: "archivebox")
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
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                            .font(.headline)
                    }
                }
            }
        }
    }
#endif
    
    
    func deleteArchivedAddresses() async {
        if settingsViewModel.selectedArchivedAddresses.isEmpty {
            settingsViewModel.showAlert(with: "Select addresses to delete.")
            return
        }
        
        await withTaskGroup { group in
            for address in settingsViewModel.selectedArchivedAddresses {
                group.addTask {
                    await addressesController.deleteAddressFromServer(address: address)
                }
            }
        }
        
        settingsViewModel.selectedArchivedAddresses.removeAll()
    }
}

#Preview {
    SettingsView()
        .environmentObject(AddressesController.shared)
        .environmentObject(AddressesViewModel.shared)
        .environmentObject(SettingsViewModel.shared)
}
