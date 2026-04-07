//
//  AddressService.swift
//  TempBox
//
//  Created by Rishi Singh on 06/04/26.
//

import Foundation

@MainActor
final class AddressService: AddressServiceProtocol {
    private let repository: any AddressRepositoryProtocol
    private let networkService: any MailTMNetworkServiceProtocol

    init(repository: any AddressRepositoryProtocol, networkService: any MailTMNetworkServiceProtocol) {
        self.repository = repository
        self.networkService = networkService
    }

    // MARK: - Read

    func fetchAll() -> [Address] {
        repository.fetchAll()
    }

    func isAddressUnique(email: String) -> (Bool, Bool) {
        let addresses = repository.fetchAll()
        let match = addresses.first { $0.address == email }
        return (match == nil, match?.isArchived ?? false)
    }

    // MARK: - Create

    func addAddress(account: Account, token: String, password: String, name: String, folder: Folder?) async {
        let newAddress = Address(
            id: account.id,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : name,
            address: account.address,
            quota: account.quota,
            used: account.used,
            createdAt: account.createdAtDate,
            updatedAt: account.updatedAtDate,
            token: token,
            password: password,
            folder: folder
        )
        if let folder = folder {
            var addresses = folder.addresses ?? []
            addresses.append(newAddress)
            folder.addresses = Array(Set(addresses))
        }
        repository.insert(newAddress)
        repository.save()
    }

    func loginAndSave(v1Address: ExportVersionOneAddress) async -> (Bool, String) {
        let newAddress = Address(
            id: v1Address.id,
            name: v1Address.addressName,
            address: v1Address.authenticatedUser.account.address,
            quota: v1Address.authenticatedUser.account.quota,
            used: v1Address.authenticatedUser.account.used,
            createdAt: v1Address.authenticatedUser.account.createdAt.validateAndToDate() ?? Date.now,
            updatedAt: v1Address.authenticatedUser.account.updatedAt.validateAndToDate() ?? Date.now,
            token: v1Address.authenticatedUser.token,
            password: v1Address.password
        )
        do {
            let tokenData = try await networkService.authenticate(
                address: v1Address.authenticatedUser.account.address,
                password: v1Address.password
            )
            newAddress.token = tokenData.token
            repository.insert(newAddress)
            repository.save()
            return (true, "Success")
        } catch {
            return (false, error.localizedDescription)
        }
    }

    func loginAndSave(v2Address: ExportVersionTwoAddress) async -> (Bool, String) {
        let newAddress = Address(
            id: v2Address.id,
            name: v2Address.addressName,
            address: v2Address.email,
            quota: 0,
            used: 0,
            isArchived: v2Address.archived == "Yes",
            createdAt: v2Address.createdAtDate,
            updatedAt: v2Address.createdAtDate,
            token: "",
            password: v2Address.password
        )
        do {
            let tokenData = try await networkService.authenticate(address: v2Address.email, password: v2Address.password)
            let accountData = try await networkService.fetchAccount(id: tokenData.id, token: tokenData.token)
            newAddress.token = tokenData.token
            newAddress.quota = accountData.quota
            newAddress.used = accountData.used
            newAddress.createdAt = accountData.createdAtDate
            newAddress.updatedAt = accountData.updatedAtDate
            repository.insert(newAddress)
            repository.save()
            return (true, "Success")
        } catch {
            return (false, error.localizedDescription)
        }
    }

    // MARK: - Update

    func loginAndRestore(_ address: Address) async -> (Bool, String) {
        do {
            let tokenData = try await networkService.authenticate(address: address.address, password: address.password)
            address.token = tokenData.token
            await toggleArchiveStatus(address)
            return (true, "Success")
        } catch {
            return (false, error.localizedDescription)
        }
    }

    func updateAddress(_ address: Address) {
        address.updatedAt = Date.now
        repository.save()
    }

    func toggleArchiveStatus(_ address: Address) async {
        address.isArchived.toggle()
        address.folder = nil
        address.updatedAt = Date.now
        repository.save()
    }

    // MARK: - Delete

    func deleteAddress(_ address: Address) {
        address.isDeleted = true
        address.updatedAt = Date.now
        repository.save()
    }

    func deleteAddressFromServer(_ address: Address) async {
        guard let token = address.token, !token.isEmpty else {
            permanentlyDelete(address)
            return
        }
        do {
            try await networkService.deleteAccount(id: address.id, token: token)
        } catch {
            // Best-effort server delete — always clean up locally
        }
        permanentlyDelete(address)
    }

    func permanentlyDelete(_ address: Address) {
        repository.delete(address)
        repository.save()
    }
}
