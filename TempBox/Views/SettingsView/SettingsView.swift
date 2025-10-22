//
//  SettingsView.swift
//  TempBox
//
//  Created by Rishi Singh on 02/05/25.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var addressesController: AddressesController
    @EnvironmentObject private var settingsViewModel: SettingsViewModel
    @EnvironmentObject private var appController: AppController
    @EnvironmentObject private var iapManager: IAPManager
    
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
                            ToolbarItem(placement: .confirmationAction) {
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
            NavigationListBuilder()
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
            case .tipJarPage:
                TipJarView()
            case .archive:
                ArchiveView()
            case .aboutPage:
                AboutView()
            case .folders:
                ManageFoldersView()
            }
        }
        .frame(minWidth: 700, minHeight: 400)
    }
    
    @ViewBuilder
    private func NavigationListBuilder() -> some View {
        let selectionBinding = Binding(get: {
            settingsViewModel.selectedSetting
        }, set: { newValue in
            DispatchQueue.main.async {
                settingsViewModel.selectedSetting = newValue
            }
        })
        List(selection: selectionBinding) {
            NavigationLink(value: SettingPage.importPage) {
                Label("Import Addresses", systemImage: "square.and.arrow.down")
            }
            NavigationLink(value: SettingPage.exportPage) {
                Label("Export Addresses", systemImage: "square.and.arrow.up")
            }
            NavigationLink(value: SettingPage.archive) {
                Label("Archived Addresses", systemImage: "archivebox")
            }
            NavigationLink(value: SettingPage.folders) {
                Label("Manage Folders", systemImage: "folder")
            }
            
            Text("")
            NavigationLink(value: SettingPage.tipJarPage) {
                Label {
                    Text("Tip Jar")
                } icon: {
                    Text(Locale.current.currencySymbol ?? "$")
                        .padding(7)
                        .background(settingsViewModel.selectedSetting == .tipJarPage ? Color.primary.opacity(0.2) : Color.accentColor.opacity(0.2))
                        .foregroundColor(settingsViewModel.selectedSetting == .tipJarPage ? Color.primary : Color.accentColor)
                        .clipShape(Circle())
                        .frame(height: 20)
                }
            }
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
        let accentColor = appController.accentColor(colorScheme: colorScheme);
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
                NavigationLink {
                    ManageFoldersView()
                } label: {
                    Label("Manage Folders", systemImage: "folder")
                }
            }
            
            Section {
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
                NavigationLink {
                    TipJarView()
                } label: {
                    Label {
                        Text("Tip Jar")
                    } icon: {
                        Text(Locale.current.currencySymbol ?? "$")
                            .padding(7)
                            .background(accentColor.opacity(0.2))
                            .foregroundColor(accentColor)
                            .clipShape(Circle())
                            .frame(height: 20)
                    }
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
