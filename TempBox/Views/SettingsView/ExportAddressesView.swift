//
//  ExportAddressesView.swift
//  TempBox
//
//  Created by Rishi Singh on 02/05/25.
//

import SwiftUI
import SwiftData

struct ExportAddressesView: View {
    @EnvironmentObject private var settingsViewModel: SettingsViewModel
    @EnvironmentObject private var addressesController: AddressesController
        
    @State private var showExportAlert: Bool = false
    
    @Query(filter: #Predicate<Address> { !$0.isArchived }, sort: [SortDescriptor(\Address.createdAt, order: .reverse)])
    private var addresses: [Address]
    
    var body: some View {
        Group {
#if os(iOS)
            IOSView()
#elseif os(macOS)
            MacOSView()
#endif
        }
        .onAppear(perform: {
            showExportAlert = true
        })
        .alert("Alert!", isPresented: $showExportAlert) {
            Button("I Understand") {}
        } message: {
            Text("The exported addresses can be used to login and read your emails. Please store them securly.")
        }
        .navigationTitle("Export Addresses")
    }
    
#if os(iOS)
    @ViewBuilder
    func IOSView() -> some View {
        List(addresses, id: \.self, selection: $settingsViewModel.selectedExportAddresses) { address in
            HStack {
                VStack(alignment: .leading) {
                    Text(address.ifNameElseAddress)
                    Text(address.ifNameThenAddress)
                        .font(.caption.bold())
                    if let safeErrMess = settingsViewModel.errorDict[address.id] {
                        Text(safeErrMess)
                            .font(.caption.bold())
                            .foregroundStyle(.red)
                    }
                }
                Spacer()
            }
        }
        .environment(\.editMode, .constant(.active))
        .toolbar {
            Menu {
                Text("Choose Export Type")
                    .disabled(true)
                    .font(.caption)
                Divider()
                ForEach(ExportTypes.allCases) { type in
                    Button {
                        settingsViewModel.selectedExportType = type
                    } label: {
                        Label(type.displayName, systemImage: type.symbol)
                    }
                }
            } label: {
                Label(settingsViewModel.selectedExportType.displayName, systemImage: settingsViewModel.selectedExportType.symbol)
            }
        }
        .toolbar(content: {
            ToolbarItemGroup(placement: .bottomBar) {
                Button("Unselect All") {
                    settingsViewModel.selectedExportAddresses = []
                }
                Button("Select All") {
                    settingsViewModel.selectedExportAddresses = Set(addresses)
                }
                Spacer()
                Button("Export") {
                    settingsViewModel.exportAddresses()
                }
                .disabled(settingsViewModel.selectedExportAddresses.isEmpty)
            }
        })
        .navigationBarTitleDisplayMode(.inline)
        .background(content: {
            ExporterView()
        })
    }
#endif
    
#if os(macOS)
    @ViewBuilder
    func MacOSView() -> some View {
        // using this exportTypeSelectionBinding binding because simply binding the "settingsViewModel.selectedExportType" gave error "Publishing changes from within view updates is not allowed, this will cause undefined behavior."
        let exportTypeSelectionBinding = Binding {
            settingsViewModel.selectedExportType
        } set: { newVal in
            Task { @MainActor in
                settingsViewModel.selectedExportType = newVal
            }
        }

        VStack(alignment: .leading) {
            MacCustomSection {
                HStack {
                    Text("Export Type")
                    Spacer()
                    Picker("", selection: exportTypeSelectionBinding) {
                        ForEach(ExportTypes.allCases) { exportType in
                            Text(exportType.displayName).tag(exportType)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 250)
                }
            }
            .padding(.top)
            MacCustomSection {
                VStack {
                    AddressView()
                    SelectionButtons()
                }
            }
            .padding(.bottom)
        }
        .background(content: {
            ExporterView()
        })
    }
    
    @ViewBuilder
    func AddressView() -> some View {
        List {
            ForEach(addresses) { address in
                HStack {
                    Toggle("", isOn: Binding(get: {
                        settingsViewModel.selectedExportAddresses.contains(address)
                    }, set: { newVal in
                        if newVal {
                            settingsViewModel.selectedExportAddresses.insert(address)
                        } else {
                            settingsViewModel.selectedExportAddresses.remove(address)
                        }
                    }))
                    .toggleStyle(.checkbox)
                    VStack(alignment: .leading) {
                        Text(address.ifNameElseAddress)
                            .font(.body)
                        Text(address.ifNameThenAddress)
                            .font(.caption)
                    }
                    Spacer()
                    if let safeErrMess = settingsViewModel.errorDict[address.id] {
                        Text(safeErrMess)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    func SelectionButtons() -> some View {
        HStack {
            Spacer()
            Button("Unselect All", role: .cancel) {
                settingsViewModel.selectedExportAddresses = []
            }
            Button("Select All") {
                settingsViewModel.selectedExportAddresses = Set(addresses)
            }
            Button("Export") {
                settingsViewModel.exportAddresses()
            }
            .buttonStyle(.borderedProminent)
            .disabled(settingsViewModel.selectedExportAddresses.isEmpty)
        }
    }
#endif
    
    @ViewBuilder
    func ExporterView() -> some View {
        Group {
            if settingsViewModel.selectedExportType == .encoded {
                EmptyView()
                    .fileExporter(
                        isPresented: $settingsViewModel.isExportingTextFile,
                        document: settingsViewModel.textFileDocument,
                        contentType: TextFileDocument.contentType,
                        defaultFilename: "\(settingsViewModel.exportFileName).txt",
                        onCompletion: settingsViewModel.handleExport
                    )
            } else if settingsViewModel.selectedExportType == .JSON {
                EmptyView()
                    .fileExporter(
                        isPresented: $settingsViewModel.isExportingJSONFile,
                        document: settingsViewModel.jsonFileDocument,
                        contentType: JSONFileDocument.contentType,
                        defaultFilename: "\(settingsViewModel.exportFileName).json",
                        onCompletion: settingsViewModel.handleExport
                    )
            } else if settingsViewModel.selectedExportType == .CSV {
                EmptyView()
                    .fileExporter(
                        isPresented: $settingsViewModel.isExportingCSVFile,
                        document: settingsViewModel.csvFileDocument,
                        contentType: CSVFileDocument.contentType,
                        defaultFilename: "\(settingsViewModel.exportFileName).csv",
                        onCompletion: settingsViewModel.handleExport
                    )
            }
        }
    }
}
