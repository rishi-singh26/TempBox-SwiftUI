//
//  AddAddressViewModel.swift
//  TempBox
//
//  Created by Rishi Singh on 01/05/25.
//

import Foundation
import Combine
import CoreData
import SwiftUI

@MainActor
class AddAddressViewModel: ObservableObject {
    @Published var isLoading: Bool = false;
    // MARK: - Address variables
    @Published var addressName: String = ""
    @Published var address: String = ""
    
    @Published var password: String = ""
    @Published var shouldUseRandomPassword: Bool = false {
        willSet {
            if newValue {
                generateRandomPass()
            } else {
                password = ""
            }
        }
    }
    
    @Published var selectedFolder: Folder? = nil
    @Published var showNewFolderForm: Bool = false
    
    var isPasswordValid: Bool {
        (password != "" && password.count >= 6) || shouldUseRandomPassword
    }
    
    // MARK: - Domain variables
    @Published var domains = [Domain]()
    // TODO: Remove the defalut domain
    @Published var selectedDomain: Domain = Domain(
        id: "",
        domain: "",
        isActive: false,
        isPrivate: false,
        createdAt: Date.now.ISO8601Format(),
        updatedAt: Date.now.ISO8601Format()
    )
    
    // MARK: - Error Alert variables
    @Published var errorMessage = ""
    @Published var showErrorAlert = false
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
    
    // MARK: Create Address properties
    @Published var isCreatingAddress = false
    var subscriptions: Set<AnyCancellable> = []
    
    // MARK: - Add address or Login
    @Published var selectedAuthMode: AuthTypes = .create {
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
            let domainResponse = try await MailTMService.fetchDomains()
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
