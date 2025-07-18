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
    @Published var shouldUseRandomAddress: Bool = false {
        willSet {
            if newValue {
                generateRandomAddress()
            } else {
                address = ""
            }
        }
    }
    
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
    
    // MARK: Create Address properties
    @Published var isCreatingAddress = false
    var subscriptions: Set<AnyCancellable> = []
    
    // MARK: - Add address or Login
    @Published var selectedAuthMode: AuthTypes = .create
    
    var submitBtnText: String {
        selectedAuthMode == .create ? "Create" : "Login"
    }
    
    init() {
        Task {
            await loadDomains()
        }
    }
    
    func loadDomains() async {
        do {
            let domainResponse = try await MailTMService.fetchDomains()
            domains = domainResponse
            if !domains.isEmpty {
                self.selectedDomain = domains[0]
            }
        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
    }
    
    func generateRandomAddress() {
        address = String.generateRandomString(of: 10)
    }
    
    func generateRandomPass() {
        password = String.generateRandomString(of: 12, useUpperCase: true, useNumbers: true, useSpecialCharacters: true)
    }
    
    func getEmail() -> String {
        return selectedAuthMode == .create ? "\(self.address)@\(self.selectedDomain.domain)" : self.address
    }
    
    func validateInput() -> Bool {
        // Common validation for address and password
        if address.isEmpty || password.isEmpty {
            self.errorMessage = "Please enter address and password"
            self.showErrorAlert = true
            return false
        }

        // Additional validation for new address creation
        if selectedAuthMode == .create && selectedDomain.id.isEmpty {
            self.errorMessage = "Please select a domain"
            self.showErrorAlert = true
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
