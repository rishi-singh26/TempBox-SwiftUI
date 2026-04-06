//
//  AddressRepositoryProtocol.swift
//  TempBox
//
//  Created by Rishi Singh on 06/04/26.
//

import SwiftData

@MainActor
protocol AddressRepositoryProtocol {
    func fetchAll() -> [Address]
    func insert(_ address: Address)
    func delete(_ address: Address)
    func save()
}
