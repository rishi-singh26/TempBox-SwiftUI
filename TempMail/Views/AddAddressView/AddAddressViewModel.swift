//
//  AddAddressViewModel.swift
//  TempBox
//
//  Created by Rishi Singh on 01/05/25.
//

import Foundation
import MailTMSwift
import Combine
import CoreData
import SwiftUI

class AddAddressViewModel: ObservableObject {
    // MARK: - Services
    private let accountService = MTAccountService()
    let domainService = MTDomainService()
    
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
    @Published var domains = [MTDomain]()
    @Published var selectedDomain: MTDomain = MTDomain(id: "", domain: "", isActive: false, isPrivate: false, createdAt: Date.now, updatedAt: Date.now)
    
    // MARK: - Error Alert variables
    @Published var errorMessage = ""
    @Published var showErrorAlert = false
    
    // MARK: Create Address properties
    @Published var isCreatingAddress = false
    var subscriptions: Set<AnyCancellable> = []
    
    // MARK: - Add address or Login
    let authOptions = ["New", "Login"]
    @Published var selectedAuthMode = "New"
    @Published var isCreatingNewAddress = true
    
    init() {
        loadDomains()
    }
    
    func loadDomains() {
        domainService.getAllDomains { (result: Result<[MTDomain], MTError>) in
            switch result {
              case .success(let domains):
                self.domains = domains
                if !domains.isEmpty {
                    self.selectedDomain = domains[0]
                }
              case .failure(let error):
                self.errorMessage = error.localizedDescription
                self.showErrorAlert = true
            }
        }
    }
    
    func generateRandomAddress() {
        address = String.generateRandomString(of: 10)
    }
    
    func generateRandomPass() {
        password = String.generateRandomString(of: 12, useUpperCase: true, useNumbers: true, useSpecialCharacters: true)
    }
    
    func getEmail() -> String {
        return isCreatingNewAddress ? "\(self.address)@\(self.selectedDomain.domain)" : self.address
    }
    
    func validateInput() -> Bool {
        // Common validation for address and password
        if address.isEmpty || password.isEmpty {
            self.errorMessage = "Please enter address and password"
            self.showErrorAlert = true
            return false
        }

        // Additional validation for new address creation
        if isCreatingNewAddress && selectedDomain.id.isEmpty {
            self.errorMessage = "Please select a domain"
            self.showErrorAlert = true
            return false
        }

        return true
    }
}
