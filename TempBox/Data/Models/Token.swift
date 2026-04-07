//
//  Token.swift
//  TempBox
//
//  Created by Rishi Singh on 10/06/25.
//

import Foundation

struct TokenRequest: Codable {
    let address: String
    let password: String
}

struct TokenResponse: Codable {
    let id: String
    let token: String
}
