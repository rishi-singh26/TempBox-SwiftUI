//
//  AddressStore.swift
//  TempBox
//
//  Created by Rishi Singh on 06/04/26.
//

import SwiftUI

@Observable
@MainActor
final class AddressStore {
    // MARK: - Navigation state
    var selectedAddress: Address? {
        willSet { selectedMessage = nil }
    }
    var selectedMessage: Message? {
        didSet {
            if let msg = selectedMessage, !msg.seen {
                Task { await messageService.updateSeenStatus(msg) }
            }
        }
    }
    var showUnifiedInbox: Bool = false

    // MARK: - Fetch state
    var isLoading: Bool = false
    var messageStore: [String: MessageStore] = [:]
    var loadingCompleteMessage: Bool = false

    // MARK: - Error / notification
    var errorMessage: String?
    var showError: Bool = false

    // MARK: - Private
    private var addresses: [Address] = []
    private let addressService: any AddressServiceProtocol
    private let messageService: any MessageServiceProtocol

    // MARK: - Init

    init(addressService: any AddressServiceProtocol, messageService: any MessageServiceProtocol) {
        self.addressService = addressService
        self.messageService = messageService
        Task { await fetchAddresses() }
    }

    // MARK: - Address Fetch

    func fetchAddresses() async {
        isLoading = true
        addresses = addressService.fetchAll()
        await fetchMessagesForAllAddresses()
        isLoading = false
    }

    private func fetchMessagesForAllAddresses() async {
        await withTaskGroup(of: Void.self) { group in
            for address in addresses where !address.isArchived {
                guard let token = address.token, !token.isEmpty else { continue }
                _ = token // suppress unused warning
                group.addTask { await self.fetchMessages(for: address) }
            }
        }
    }

    // MARK: - Message Fetch

    func fetchMessages(for address: Address) async {
        guard let token = address.token, !token.isEmpty else { return }
        _ = token
        updateMessageStore(for: address, store: MessageStore(isFetching: true, error: nil))
        do {
            try await messageService.fetchMessages(for: address)
            updateMessageStore(for: address, store: MessageStore(isFetching: false, error: nil))
        } catch {
            updateMessageStore(for: address, store: MessageStore(isFetching: false, error: error.localizedDescription))
        }
    }

    func fetchMessages(for addressId: String) async {
        if let address = addresses.first(where: { $0.id == addressId }) {
            await fetchMessages(for: address)
        }
    }

    func fetchCompleteMessage(of message: Message) async {
        loadingCompleteMessage = true
        defer { loadingCompleteMessage = false }
        await messageService.fetchCompleteMessage(of: message)
    }

    // MARK: - Address Mutations

    func addAddress(account: Account, token: String, password: String, name: String, folder: Folder?) async {
        await addressService.addAddress(account: account, token: token, password: password, name: name, folder: folder)
        await fetchAddresses()
    }

    func loginAndSave(v1Address: ExportVersionOneAddress) async -> (Bool, String) {
        let result = await addressService.loginAndSave(v1Address: v1Address)
        if result.0 { await fetchAddresses() }
        return result
    }

    func loginAndSave(v2Address: ExportVersionTwoAddress) async -> (Bool, String) {
        let result = await addressService.loginAndSave(v2Address: v2Address)
        if result.0 { await fetchAddresses() }
        return result
    }

    func loginAndRestore(_ address: Address) async -> (Bool, String) {
        let result = await addressService.loginAndRestore(address)
        if result.0 { await fetchAddresses() }
        return result
    }

    func updateAddress(_ address: Address) {
        addressService.updateAddress(address)
    }

    func deleteAddress(_ address: Address) async {
        addressService.deleteAddress(address)
        await fetchAddresses()
    }

    func deleteAddressFromServer(_ address: Address) async {
        await addressService.deleteAddressFromServer(address)
        await fetchAddresses()
    }

    func permanentlyDelete(_ address: Address) async {
        addressService.permanentlyDelete(address)
        await fetchAddresses()
    }

    func toggleArchiveStatus(_ address: Address) async {
        await addressService.toggleArchiveStatus(address)
        await fetchAddresses()
    }

    // MARK: - Message Mutations

    func deleteMessage(message: Message) async {
        await messageService.deleteMessage(message)
    }

    func updateMessageSeenStatus(messageData: Message) async {
        await messageService.updateSeenStatus(messageData)
    }

    // MARK: - Downloads

    func downloadMessageResource(message: Message, address: Address) async -> Data? {
        await messageService.downloadMessageResource(message: message, address: address)
    }

    // MARK: - Helpers

    func isAddressUnique(email: String) -> (Bool, Bool) {
        addressService.isAddressUnique(email: email)
    }

    func updateMessageStore(for address: Address, store: MessageStore) {
        messageStore[address.id] = store
    }

    func updateMessageSelection(message: Message?) async {
        if let msg = message, let addr = msg.address {
            selectedAddress = addr
            selectedMessage = msg
        }
    }

    func show(error message: String) {
        errorMessage = message
        showError = true
    }

    func clearError() {
        errorMessage = nil
        showError = false
    }
}
