//
//  AddressRepository.swift
//  TempBox
//
//  Created by Rishi Singh on 06/04/26.
//

import SwiftData
import SwiftUI

@MainActor
final class AddressRepository: AddressRepositoryProtocol {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchAll() -> [Address] {
        let descriptor = FetchDescriptor<Address>(
            predicate: #Predicate<Address> { !$0.isDeleted },
            sortBy: [SortDescriptor(\Address.createdAt, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func insert(_ address: Address) {
        modelContext.insert(address)
    }

    func delete(_ address: Address) {
        modelContext.delete(address)
    }

    func save() {
        do {
            try modelContext.save()
        } catch {
            print("AddressRepository: failed to save — \(error.localizedDescription)")
        }
    }
}
