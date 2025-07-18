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
    @EnvironmentObject private var appController: AppController
    @EnvironmentObject private var iapManager: IAPManager
    
    @Environment(\.openURL) var openURL
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Group {
#if os(macOS)
            MacOSSettings()
#elseif os(iOS)
            if DeviceType.isIphone {
                IOSSettings()
            } else {
                NavigationView {
                    IOSSettings()
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button("Done") {
                                    dismiss()
                                }
                            }
                        }
                }
            }
#endif
        }
        .accentColor(appController.accentColor(colorScheme: colorScheme))
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
    private func MacOSSettings() -> some View {
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
//                NavigationLink(value: SettingPage.appColorPage) {
//                    Label("Change App Color", systemImage: "paintpalette")
//                }
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
            .navigationSplitViewColumnWidth(min: 170, ideal: 190, max: 280)
            .onChange(of: settingsViewModel.selectedSetting, { oldValue, newValue in
                settingsViewModel.handleNavigationChange(oldValue, newValue)
            })
            .toolbar(content: MacOSToolbarBuilder)
        } detail: {
            switch settingsViewModel.selectedSetting {
            case .importPage:
                ImportAddressesView()
            case .exportPage:
                ExportAddressesView()
            case .appIconPage:
                EmptyView()
            case .appColorPage:
                EmptyView()
            case .archive:
                ArchiveView()
            case .aboutPage:
                AboutView()
            }
        }
        .frame(minWidth: 700, minHeight: 400)
    }
    
    @ToolbarContentBuilder
    private func MacOSToolbarBuilder() -> some ToolbarContent {
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
    private func IOSSettings() -> some View {
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
                if !iapManager.availableProducts.isEmpty && !appController.hasTipped {
                    TipJarCardView()
                        .padding(.bottom)
                }
                NavigationLink {
                    AppIconView()
                } label: {
                    Label("App Icon", systemImage: "command")
                }
                NavigationLink {
                    AppColorView()
                } label: {
                    Label("Accent Color", systemImage: "paintpalette")
                }
            } footer: {
                Text(appController.hasTipped ? "Thanks for the tip!" : "Tip any amount to unlock!")
            }
            
            Section {
                NavigationLink {
                    AboutView()
                } label: {
                    Label("About TempBox", systemImage: "info.circle")
                }
            } footer: {
                Text("TempBox is lovingly developed in India. 🇮🇳")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Settings")
    }
#endif
    
    
    private func deleteArchivedAddresses() async {
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
