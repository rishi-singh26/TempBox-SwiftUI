//
//  Domain.swift
//  TempBox
//
//  Created by Rishi Singh on 10/06/25.
//

import Foundation

struct Domain: Codable, Identifiable, Hashable {
    let id: String
    let domain: String
    let isActive: Bool
    let isPrivate: Bool
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, domain, isActive, isPrivate, createdAt, updatedAt
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
