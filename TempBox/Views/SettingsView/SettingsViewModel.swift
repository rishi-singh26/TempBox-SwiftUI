//
//  SettingsViewModel.swift
//  TempBox
//
//  Created by Rishi Singh on 02/05/25.
//

import SwiftUI
import UniformTypeIdentifiers

class SettingsViewModel: ObservableObject {
    static var shared = SettingsViewModel()
    
    @Published var selectedSetting: SettingPage = .importPage
    @Published var navigationStack: [SettingPage] = [.importPage]
    @Published var currentPointer: Int = 0
    @Published var isNavigatingManually = true
    
    
    // MARK: - Import Page properties
    @Published var isPickingFile: Bool = false
    /// Data captured from import file
    @Published var v1ImportData: ExportVersionOne? = nil
    /// Selected V1 addresses for import/
    @Published var selectedV1Addresses: Set<ExportVersionOneAddress> = []
    /// Dictonary of errors after import attempt [messageId: errorMessage]
    @Published var errorDict: [String: String] = [:]
    /// Data captured from version 2 import file
    @Published var v2ImportData: ExportVersionTwo? = nil
    /// Selected V2 addresses for import/
    @Published var selectedV2Addresses: Set<ExportVersionTwoAddress> = []
    /// Version of the import data, application logic will deped on this
    @Published var importDataVersion: String? = nil
    var isImportButtonDisabled: Bool {
        selectedV1Addresses.isEmpty && selectedV2Addresses.isEmpty
    }
    
    /// Address in the selected import, the addresses already in swift data are filtered out
    func getV1Addresses(addresses: [Address]) -> [ExportVersionOneAddress] {
        return (v1ImportData?.addresses ?? []).filter { address in
            let idMatches = addresses.first(where: { existingAddress in
                address.id == existingAddress.id && !existingAddress.isDeleted
            })
            return idMatches == nil
        }
    }
    
    /// Address in the selected import file, the addresses already in swift data are filtered out
    func getV2Addresses(addresses: [Address]) -> [ExportVersionTwoAddress] {
        return (v2ImportData?.addresses ?? []).filter { address in
            let idMatches = addresses.first(where: { existingAddress in
                address.id == existingAddress.id && !existingAddress.isDeleted
            })
            return idMatches == nil
        }
    }
    
    func selectAllAddresses(addresses: [Address]) {
        if importDataVersion == ExportVersionOne.staticVersion {
            selectedV1Addresses = Set(getV1Addresses(addresses: addresses))
        } else if importDataVersion == ExportVersionTwo.staticVersion {
            selectedV2Addresses = Set(getV2Addresses(addresses: addresses))
        }
    }
    
    func unSelectAllAddresses() {
        if importDataVersion == ExportVersionOne.staticVersion {
            selectedV1Addresses = []
        } else if importDataVersion == ExportVersionTwo.staticVersion {
            selectedV2Addresses = []
        }
    }
    
    // MARK: - Export page properties
    @Published var selectedExportAddresses: Set<Address> = []
    @Published var selectedExportType: ExportTypes = .encoded
    
    @Published var textFileDocument = TextFileDocument(text: "Hello World!")
    @Published var isExportingTextFile: Bool = false
    @Published var jsonFileDocument = JSONFileDocument.dummyDoc
    @Published var isExportingJSONFile: Bool = false
    @Published var csvFileDocument = CSVFileDocument(csvText: "")
    @Published var isExportingCSVFile: Bool = false
    
    var exportFileName: String {
        "TempBoxExport-\(Date.now.dd_mmm_yyyy())"
    }
    
    func exportAddresses() {
        if selectedExportAddresses.isEmpty {
            showAlert(with: "Please select addresses to export.")
            return
        }
        
        let exportData = ExportVersionTwo(addresses: Array(selectedExportAddresses).map({ address in
            ExportVersionTwoAddress(addressName: address.name, id: address.id, email: address.address, password: address.password, archived: "No")
        }))
        
        switch selectedExportType {
        case .encoded:
            do {
                let json: String = try exportData.toJSON()
                textFileDocument = TextFileDocument(text: try Base64Service.encodeBase64(json))
                isExportingTextFile = true
            } catch {
                showAlert(with: error.localizedDescription)
            }
        case .JSON:
            do {
                jsonFileDocument = try JSONFileDocument(object: exportData)
                isExportingJSONFile = true
            } catch {
                showAlert(with: error.localizedDescription)
            }
        case .CSV:
            csvFileDocument = CSVFileDocument(csvText: exportData.toCSV())
            isExportingCSVFile = true
        }
        
        selectedExportAddresses = []
    }
    func handleExport(_ result: Result<URL, any Error>) -> Void {
        var message = ""
        switch result {
        case .success(let url):
            message = "Exported successfully"
        case .failure(let error):
            message = "Export failed"
        }
        showAlert(with: message)
    }
    
    
    // MARK: - Archive page properties
    @Published var selectedArchivedAddresses: Set<Address> = []
    @Published var showArchAddrDeleteConf: Bool = false
    
    
    // MARK: - About page properties
    @Published var showLinkOpenConfirmation: Bool = false
    @Published var linkToOpen: String = ""
    
    
    // MARK: - Error handelling properties
    @Published var errorMessage: String = ""
    @Published var showErrorAlert: Bool = false
    
    func showAlert(with message: String) {
        errorMessage = message
        showErrorAlert = true
    }
    
    
    // MARK: - Import data handlers
    func pickFileForImport() {
        isPickingFile = true
    }

    func importData(from result: Result<[URL], any Error>) {
        let (_, content, statusMessage) = FileService.getFileContentFromFileImporterResult(result)
        
        guard let content else {
            showAlert(with: statusMessage)
            return
        }

        let (v1Data, v2Data, message) = ImportExportService.decodeDataForImport(from: content)
        
        self.v1ImportData = v1Data
        self.v2ImportData = v2Data
        selectedV1Addresses = []
        selectedV2Addresses = []

        if v1Data == nil && v2Data == nil {
            showAlert(with: message)
        }
        
        importDataVersion = v1Data?.version ?? v2Data?.version ?? nil
    }
    
    
    // MARK: - Navigation helpers
    var backButtonDisabled: Bool {
        currentPointer <= 0
    }
    
    var forwardBtnDisabled: Bool {
        currentPointer >= navigationStack.count - 1
    }
    
    func handleNavigationChange(_ oldValue: SettingPage, _ newValue: SettingPage) {
        guard isNavigatingManually else { return }

        if currentPointer == navigationStack.count - 1 {
            navigationStack.append(newValue)
            currentPointer += 1
        } else if navigationStack[currentPointer] != newValue {
            navigationStack = Array(navigationStack.prefix(upTo: currentPointer + 1))
            navigationStack.append(newValue)
            currentPointer += 1
        }
    }
    
    func goBack() {
        if currentPointer > 0 {
            currentPointer -= 1
            isNavigatingManually = false
            selectedSetting = navigationStack[currentPointer]
            DispatchQueue.main.async {
                self.isNavigatingManually = true
            }
        }
    }

    func goForward() {
        if currentPointer < navigationStack.count - 1 {
            currentPointer += 1
            isNavigatingManually = false
            selectedSetting = navigationStack[currentPointer]
            DispatchQueue.main.async {
                self.isNavigatingManually = true
            }
        }
    }
}


// MARK: - Export Types
enum ExportTypes: String, CaseIterable, Identifiable {
    case encoded = "encoded"
    case JSON = "JSON"
    case CSV = "CSV"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .encoded: return "Encoded"
        case .JSON: return "JSON"
        case .CSV: return "CSV"
        }
    }
}
