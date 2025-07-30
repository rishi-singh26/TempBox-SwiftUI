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
    @EnvironmentObject private var appController: AppController
    
    @Environment(\.colorScheme) private var colorScheme
    
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
        let accentColor = appController.accentColor(colorScheme: colorScheme)
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
            Button {
                settingsViewModel.showExportTypePicker = true
            } label: {
                Text(settingsViewModel.selectedExportType.displayName)
                    .contentTransition(.numericText())
                    .frame(minWidth: 80)
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
        .systemTrayView($settingsViewModel.showExportTypePicker) {
            ExportTypePicker(accentColor: accentColor)
        }
    }
    
    @ViewBuilder
    private func ExportTypePicker(accentColor: Color) -> some View {
        VStack(spacing: 20) {
            VStack(spacing: 12) {
                HStack {
                    Text("Choose Export Type")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Spacer(minLength: 0)
                    
                    Button {
                        settingsViewModel.showExportTypePicker = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(Color.gray, Color.primary.opacity(0.1))
                    }
                }
                .padding(.bottom, 25)
                
                VStack(alignment: .leading) {
                    Text(settingsViewModel.selectedExportType.description)
                        .multilineTextAlignment(.leading)
                        .transition(.blurReplace)
                        .padding(20)
                }
                .frame(maxWidth: .infinity)
                .background(.ultraThinMaterial, in: .rect(cornerRadius: 25))
                .padding(.bottom, 25)
                
                ForEach(ExportTypes.allCases) { exportType in
                    let isSelected: Bool = exportType == settingsViewModel.selectedExportType
                    
                    HStack(spacing: 10) {
//                        Label(exportType.displayName, systemImage: exportType.symbol)
                        Image(systemName: exportType.symbol)
                            .frame(width: 40)
                        
                        Text(exportType.displayName)
                        
                        Spacer()
                        
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle.fill")
                            .font(.title3)
                            .contentTransition(.symbolEffect)
                            .foregroundStyle(isSelected ? accentColor : Color.gray.opacity(0.2))
                    }
                    .padding(.vertical, 6)
                    .contentShape(.rect)
                    .onTapGesture {
                        if !isSelected {
                            withAnimation(.bouncy) {
                                settingsViewModel.selectedExportType = exportType
                            }
                        }
                    }
                }
            }
            
            // Continue button
            Button {
                settingsViewModel.showExportTypePicker = false
            } label: {
                Text("Continue")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .foregroundStyle(.white)
                    .background(accentColor, in: .capsule)
            }
            .padding(.top, 15)
        }
        .padding(20)
    }
#endif
    
#if os(macOS)
    @ViewBuilder
    func MacOSView() -> some View {
        VStack(alignment: .leading) {
            MacCustomSection {
                HStack {
                    Text("Export Type")
                    Spacer()
                    Picker("", selection: $settingsViewModel.selectedExportType) {
                        ForEach(ExportTypes.allCases) { exportType in
                            Text(exportType.displayName).tag(exportType)
                        }
                    }
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
