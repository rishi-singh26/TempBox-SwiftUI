//
//  AddAddressViewModel.swift
//  TempBox
//
//  Created by Rishi Singh on 01/05/25.
//

import Foundation
import SwiftUI
import Observation

@Observable
@MainActor
class AddAddressViewModel {
    var isLoading: Bool = false

    // MARK: - Address variables
    var addressName: String = ""
    var address: String = ""

    var password: String = ""
    var shouldUseRandomPassword: Bool = false {
        willSet {
            if newValue {
                generateRandomPass()
            } else {
                password = ""
            }
        }
    }

    var selectedFolder: Folder? = nil
    var showNewFolderForm: Bool = false

    var isPasswordValid: Bool {
        (password != "" && password.count >= 6) || shouldUseRandomPassword
    }

    // MARK: - Domain variables
    var domains = [Domain]()
    var selectedDomain: Domain = Domain(
        id: "",
        domain: "",
        isActive: false,
        isPrivate: false,
        createdAt: Date.now.ISO8601Format(),
        updatedAt: Date.now.ISO8601Format()
    )

    // MARK: - Error Alert variables
    var errorMessage = ""
    var showErrorAlert = false
    func showError(with message: String) {
        withAnimation {
            errorMessage = message
            showErrorAlert = true
        }
    }
    func hideError() {
        errorMessage = ""
        showErrorAlert = false
    }

    // MARK: - Create Address properties
    var isCreatingAddress = false

    // MARK: - Add address or Login
    var selectedAuthMode: AuthTypes = .create {
        didSet {
            Task { @MainActor in
                address = ""
                hideError()
                if selectedAuthMode == .create {
                    shouldUseRandomPassword ? generateRandomPass() : nil
                } else {
                    password = ""
                }
            }
        }
    }

    var submitBtnText: String {
        selectedAuthMode == .create ? "Create" : "Login"
    }

    func loadDomains() async {
        do {
            let domainResponse = try await MailTMNetworkService.shared.fetchDomains()
            domains = domainResponse
            if !domains.isEmpty {
                self.selectedDomain = domains[0]
            }
        } catch {
            showError(with: error.localizedDescription)
        }
    }

    func generateRandomAddress() {
        address = String.generateUsername()
    }

    func generateRandomPass() {
        password = String.generatePassword(of: 12, useUpperCase: true, useNumbers: true, useSpecialCharacters: true)
    }

    func getEmail() -> String {
        return selectedAuthMode == .create ? "\(self.address)@\(self.selectedDomain.domain)" : self.address
    }

    func validateInput() -> Bool {
        if address.isEmpty {
            self.showError(with: "Please enter address")
            return false
        }

        if password.isEmpty {
            self.showError(with: "Please enter password")
            return false
        }

        // Additional validation for new address creation
        if selectedAuthMode == .create && selectedDomain.id.isEmpty {
            self.showError(with: "Please select a domain")
            return false
        }

        return true
    }
}

// MARK: - Auth Types
enum AuthTypes: String, CaseIterable, Identifiable {
    case create = "create"
    case login = "login"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .create: return "Create"
        case .login: return "Login"
        }
    }
}
