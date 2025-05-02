//
//  SettingsViewModel.swift
//  TempMail
//
//  Created by Rishi Singh on 02/05/25.
//

import SwiftUI

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
    /// Selected addresses for import/
    @Published var selectedV1Addresses: Set<AddressData> = []
    /// Dictonary of errors after import attempt [messageId: errorMessage]
    @Published var errorDict: [String: String] = [:]
    /// Data captured from version 2 import file
    @Published var v2ImportData: ExportVersionTwo? = nil
    
    /// Address in the selected import, the accounts already in swift data are filtered out
    func getV1Addresses(accounts: [Account]) -> [AddressData] {
        return (v1ImportData?.addresses ?? []).filter { address in
            let idMatches = accounts.first(where: { account in
                account.id == address.id && !account.isDeleted
            })
            return idMatches == nil
        }
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

        if v1Data == nil && v2Data == nil {
            showAlert(with: message)
        }
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
