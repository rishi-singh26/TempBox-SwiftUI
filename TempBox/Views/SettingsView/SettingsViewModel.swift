//
//  SettingsViewModel.swift
//  TempBox
//
//  Created by Rishi Singh on 02/05/25.
//

import SwiftUI
import UniformTypeIdentifiers

enum SettingPage {
    case importPage
    case exportPage
    case appIconPage
    case appColorPage
    case tipJarPage
    case archive
    case aboutPage
    case folders
}

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
    @Published var showExportTypePicker: Bool = false
    
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
            ExportVersionTwoAddress(
                addressName: address.name,
                id: address.id,
                email: address.address,
                password: address.password,
                archived: "No",
                createdAt: address.createdAt.ISO8601Format()
            )
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
        case .success:
            message = "Exported successfully"
        case .failure:
            message = "Export failed"
        }
        showAlert(with: message)
    }
    
    
    // MARK: - Archive page properties
    @Published var selectedArchivedAddresses: Set<Address> = []
    @Published var showArchAddrDeleteConf: Bool = false
    
    // MARK: - Archive page properties
    @Published var selectedFolder: Folder? = nil
    @Published var showDeleteFolderConf: Bool = false
    
    
    // MARK: - About page properties
    @Published var showLinkOpenConfirmation: Bool = false
    @Published var linkToOpen: String = ""
    func showLinkConfirmation(url: String) {
        linkToOpen = url
        showLinkOpenConfirmation.toggle()
    }
    
    
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
    
    var description: String {
        switch self {
        case .encoded:
            return "Exported data will be Base64 encoded in a .txt file containing emails and passwords. It can not be read directly without decoding. It can be easily decoded by tools available online. Keep it safe."
        case .JSON:
            return "Exported data will be in JSON format in a .json file containing emails and passwords. JSON format is easy to read and understand, keep the exported file secure to prevent unauthirized access.."
        case .CSV:
            return "Exported data will be in CSV format in a .csv file with emails and passwords. CSV is a very accessible format, keep the exported file secure to prevent unauthirized access."
        }
    }
    
//    var description: String {
//        switch self {
//        case .encoded:
//            return "Exported data will be Base64 encoded. While it can be easily decoded, it is not directly readable without decoding. Keep this file secure to prevent unauthorized access."
//        case .JSON:
//            return "Exported data will be in JSON format, containing information such as emails and passwords. This format is easy to read, data should be stored securly to prevent unauthorized access."
//        case .CSV:
//            return "Exported data will be in CSV format, saved in a .csv file, containing account information like emails and passwords. It is easy to read and should be kept secure to prevent unauthorized access."
//        }
//    }

    
    var symbol: String {
        switch self {
        case .encoded: return "text.page"
        case .JSON: return "ellipsis.curlybraces"
        case .CSV: return "table"
        }
    }
}
