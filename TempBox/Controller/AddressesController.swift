//
//  AddressesController.swift
//  TempBox
//
//  Created by Rishi Singh on 01/05/25.
//

import SwiftUI
import SwiftData
import Combine

@MainActor
class AddressesController: ObservableObject {
    // SwiftData modelContainer and modelContext
    private let modelContext: ModelContext
        
    // Published properties for UI updates
    private var addresses: [Address] = []
    @Published var isLoading: Bool = false
    @Published var messageStore: [String: MessageStore] = [:] // [AddressID: MessageStore]
    // For showing error or success message to user
    @Published var message: String?
    @Published var showMessage: Bool = false
    
    @Published var selectedAddress: Address? {
        willSet {
            selectedMessage = nil
        }
    }
    @Published var selectedMessage: Message? {
        didSet {
            if let safeMessage = selectedMessage {
                Task {
                    // Mark message as read
                    if !safeMessage.seen {
                        await updateMessageSeenStatus(messageData: safeMessage)
                    }
                }
            }
        }
    }
    @Published var showUnifiedInbox: Bool = false
    // We will fetch complete message when a message from the list is selected
    @Published var loadingCompleteMessage = false
    
    // MARK: - Initialization
    init(modelContext: ModelContext) {
        // Set up SwiftData container
        self.modelContext = modelContext
        // Load addresses on initialization
        Task { await fetchAddresses() }
    }
    
    // MARK: - Data Operations
    /// Fetches all addresses from SwiftData
    func fetchAddresses() async {
        //print("Starting fetchAddresses")
        isLoading = true
        
        do {
            let descriptor = FetchDescriptor<Address>(
                predicate: #Predicate<Address> { !$0.isDeleted },
                sortBy: [SortDescriptor(\Address.createdAt, order: .reverse)]
            )
            
            self.addresses = try modelContext.fetch(descriptor)
            //print("Fetched \(addresses.count) addresses")
            
            await fetchMessagesForAllAddresses()
            clearMessage()
        } catch {
            show(message: error.localizedDescription)
            //print("Error fetching addresses: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    private func fetchMessagesForAllAddresses() async {
        await withTaskGroup(of: Void.self) { group in
            for address in addresses where !address.isArchived {
                guard let token = address.token, !token.isEmpty else {
                    continue
                }

                group.addTask {
                    await self.fetchMessages(for: address)
                }
            }
        }
    }
    
    /// Get messages for address
    func fetchMessages(for address: Address) async {
        guard let token = address.token, !token.isEmpty else { return }
        do {
            self.updateMessageStore(for: address, store: MessageStore(isFetching: true, error: nil))
            let allMessages = try await MailTMService.fetchMessages(token: token)
            
            // Upsert messages
            var result: [Message] = []
            let currentMessages = address.messages ?? []
            for apiMsg in allMessages {
                let existing = currentMessages.first { $0.remoteId == apiMsg.id }
                if let msg = existing {
                    msg.seen = apiMsg.seen
                    result.append(msg)
                } else {
                    let msg = Message(api: apiMsg)
                    msg.address = address
                    modelContext.insert(msg)
                    result.append(msg)
                }
            }

            // Schedule background complete fetch for new messages
            let newMessages = result.filter { $0.html == nil }
            await fetchCompleteMessages(for: newMessages, address: address)
            
            self.updateMessageStore(for: address, store: MessageStore(isFetching: false, error: nil))
        } catch {
            self.updateMessageStore(for: address, store: MessageStore(isFetching: false, error: error.localizedDescription))
        }
    }
    
    func fetchCompleteMessages(for messages: [Message], address: Address) async {
        await withTaskGroup(of: Void.self) { group in
            for message in messages where !address.isArchived {
                group.addTask {
                    await self.fetchCompleteMessage(of: message)
                }
            }
        }
    }
    
    func fetchCompleteMessage(of message: Message) async {
        guard message.html == nil else { return }
        guard let token = message.address?.token, !token.isEmpty else { return }
        
        loadingCompleteMessage = true
        defer { loadingCompleteMessage = false }
        
        do {
            let completeMessage = try await MailTMService.fetchMessage(id: message.remoteId, token: token)
            message.update(with: completeMessage)
            try modelContext.save()
        } catch let decodingError as DecodingError {
            switch decodingError {
            case .keyNotFound(let key, let context):
                print("Key '\(key)' not found: \(context.debugDescription)")
            case .typeMismatch(let type, let context):
                print("Type '\(type)' mismatch: \(context.debugDescription)")
            case .valueNotFound(let type, let context):
                print("Value '\(type)' not found: \(context.debugDescription)")
            case .dataCorrupted(let context):
                print("Data corrupted: \(context.debugDescription)")
            default:
                print("Decoding error: \(decodingError.localizedDescription)")
            }
        } catch {
            self.show(message: error.localizedDescription)
        }
    }
    
    func getAddress(withID addressId: String) -> Address? {
        return addresses.first { address in
            address.id == addressId
        }
    }
    
    func isAddressUnique(email: String) -> (Bool, Bool) {
        let address = addresses.first { $0.address == email }
        return (address == nil, address?.isArchived ?? false)
    }
    
    /// Get messages for accointId
    func fetchMessages(for addressId: String) async {
        if let address = getAddress(withID: addressId) {
            await fetchMessages(for: address)
        }
    }
    
    func updateMessageSelection(message: Message?) async {
        if let safeMessage = message, let safeAddress = safeMessage.address {
            await MainActor.run {
                self.selectedAddress = safeAddress
                self.selectedMessage = message
            }
        }
    }
    
    func loginAndSaveAddress(address: ExportVersionOneAddress) async -> (Bool, String) {
        let newAddress = Address(
            id: address.id,
            name: address.addressName,
            address: address.authenticatedUser.account.address,
            quota: address.authenticatedUser.account.quota,
            used: address.authenticatedUser.account.used,
            createdAt: address.authenticatedUser.account.createdAt.validateAndToDate() ?? Date.now,
            updatedAt: address.authenticatedUser.account.updatedAt.validateAndToDate() ?? Date.now,
            token: address.authenticatedUser.token,
            password: address.password
        )
        
        do {
            let tokenData = try await MailTMService.authenticate(address: address.authenticatedUser.account.address, password: address.password)
            newAddress.token = tokenData.token
            await addAddress(newAddress)
            return (true, "Success")
        } catch {
            self.show(message: error.localizedDescription)
            return (false, error.localizedDescription)
        }
    }
    
    func loginAndSaveAddress(address: ExportVersionTwoAddress) async -> (Bool, String) {
        let newAddress = Address(
            id: address.id,
            name: address.addressName,
            address: address.email,
            quota: 0,
            used: 0,
            isArchived: address.archived == "Yes" ? true : false,
            createdAt: address.createdAtDate,
            updatedAt: address.createdAtDate, // when importing an address, updatedAt will be same as createdAt
            token: "",
            password: address.password
        )
        
        do {
            let tokenData = try await MailTMService.authenticate(address: address.email, password: address.password)
            newAddress.token = tokenData.token
            let accountData = try await MailTMService.fetchAccount(id: tokenData.id, token: tokenData.token)
            newAddress.quota = accountData.quota
            newAddress.used = accountData.used
            newAddress.createdAt = accountData.createdAtDate
            newAddress.updatedAt = accountData.updatedAtDate
            await addAddress(newAddress)
            return (true, "Success")
        } catch {
            self.show(message: error.localizedDescription)
            return (false, error.localizedDescription)
        }
    }
    
    func loginAndRestoreAddress(address: Address) async -> (Bool, String) {
        do {
            let tokenData = try await MailTMService.authenticate(address: address.address, password: address.password)
            address.token = tokenData.token
            await toggleAddressStatus(address)
            return (true, "Success")
        } catch {
            self.show(message: error.localizedDescription)
            return (false, error.localizedDescription)
        }
    }
    
    func deleteAddressFromServer(address: Address) async {
        guard let token = address.token, !token.isEmpty else { return } // handle user alert about any issues
        do {
            try await MailTMService.deleteAccount(id: address.id, token: token)
            await permanentlyDeleteAddress(address)
        } catch {
            await permanentlyDeleteAddress(address)
        }
    }
    
    func deleteMessage(message: Message) async {
        guard let token = message.address?.token, !token.isEmpty else { return }
        do {
            try await MailTMService.deleteMessage(id: message.remoteId, token: token)
            modelContext.delete(message)
        } catch {
            self.show(message: error.localizedDescription)
        }
    }
    
    func updateMessageSeenStatus(messageData: Message) async {
        guard let token = messageData.address?.token, !token.isEmpty else {
            self.show(message: "Unauthorized access attempt: Auth Token not available")
            return
        }
        
        self.clearMessage()

        do {
            let _ = try await MailTMService.updateMessageSeenStatus(id: messageData.remoteId, token: token, seen: !messageData.seen)
            messageData.seen = !messageData.seen
        } catch {
            self.show(message: error.localizedDescription)
        }
    }
    
    func downloadMessageResource(message: Message, address: Address) async -> Data? {
        guard let token = address.token, !token.isEmpty else { return nil }
        
        do {
            let data: Data = try await MailTMService.fetchMessageSource(id: message.remoteId, token: token)
            return data
        } catch {
            self.show(message: error.localizedDescription)
            return nil
        }
    }
    
    /// Add a new address from MTAccount
    func addAddress(account: Account, token: String, password: String, addressName: String, folder: Folder? = nil) async {
        let newAddress = Address(
            id: account.id,
            name: addressName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : addressName,
            address: account.address,
            quota: account.quota,
            used: account.used,
            createdAt: account.createdAtDate,
            updatedAt: account.updatedAtDate,
            token: token,
            password: password,
            folder: folder
        )
        var addresses = folder?.addresses ?? []
        addresses.append(newAddress)
        addresses = Array(Set(addresses))
        folder?.addresses = addresses
        await addAddress(newAddress)
    }
    
    /// Adds a new address
    func addAddress(_ address: Address) async {
        modelContext.insert(address)
        saveChanges()
        await fetchAddresses()
    }
    
    /// Updates an existing address
    func updateAdress(_ address: Address) {
        address.updatedAt = Date.now
        saveChanges()
//        fetchAccounts()
    }
    
    /// Delete address based on its index in the list
    func deleteAddress(indexSet: IndexSet) async {
        for index in indexSet {
            let address = addresses[index]
            await deleteAddress(address)
        }
    }
    
    /// Delete address based on its id
    func deleteAddress(id: String) async {
        let address = addresses.first { add in
            add.id == id
        }
        if let address = address {
            await deleteAddress(address)
        }
    }
    
    /// Soft deletes an address
    func deleteAddress(_ address: Address) async {
        address.isDeleted = true
        address.updatedAt = Date.now
        saveChanges()
        await fetchAddresses()
    }
    
    /// Hard deletes an address from the database
    func permanentlyDeleteAddress(_ address: Address) async {
        modelContext.delete(address)
        saveChanges()
        await fetchAddresses()
    }
    
    /// Toggles the archived status of an address
    func toggleAddressStatus(_ address: Address) async {
        address.isArchived.toggle()
        address.folder = nil // Remove address from any folder, the folder might get deleted after the address has been archived
        address.updatedAt = Date.now
        saveChanges()
        await fetchAddresses()
    }
    
    /// Sets an address's fetching messages status
    func updateMessageStore(for address: Address, store: MessageStore) {
        // Note: This only updates the transient property, not saved to SwiftData
        messageStore[address.id] = store
        // No need to save changes or refetch as this property is transient
        // Just notify observers that the address object has changed
        objectWillChange.send()
    }
    
    // MARK: - Helper Methods
    
    /// Saves changes to SwiftData
    private func saveChanges() {
        do {
            try modelContext.save()
        } catch {
            self.show(message: error.localizedDescription)
            print("Error saving context: \(error.localizedDescription)")
        }
    }
    
    /// Clears any error message
    func clearMessage() {
        self.message = nil
        self.showMessage = false
    }
    
    func show(message: String) {
        self.message = message
        self.showMessage = true
    }
}
