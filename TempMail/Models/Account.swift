//
//  Account.swift
//  TempMail
//
//  Created by Rishi Singh on 10/06/25.
//

import Foundation

struct Account: Codable, Identifiable {
    let id: String
    let address: String
    let quota: Int
    let used: Int
    let isDisabled: Bool
    let isDeleted: Bool
    let createdAt: String
    let updatedAt: String
    
    var createdAtDate: Date { createdAt.validateAndToDate() ?? Date.now }
    var updatedAtDate: Date { updatedAt.validateAndToDate() ?? Date.now }
}

struct CreateAccountRequest: Codable {
    let address: String
    let password: String
}
