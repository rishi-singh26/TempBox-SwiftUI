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
    @Published var messageStore: [String: MessageStore] = [:]
    private var msgIdToAddId: [String: String] = [:] // [MessageID: AddressId], contains the addr
    // For showing error or success message to user
    @Published var message: String?
    @Published var showMessage: Bool = false
    
    @Published var selectedAddress: Address? {
        willSet {
            selectedMessage = nil
            selectedCompleteMessage = nil
        }
    }
    @Published var selectedMessage: Message? {
        willSet {
            selectedCompleteMessage = nil
            if let safeMessage = newValue, let safeAddress = selectedAddress {
                Task {
                    // Get complete message HTML
                    await fetchCompleteMessage(of: safeMessage, address: safeAddress)
                    // Mark message as read
                    if let messageFromStore = getMessageFromStore(safeAddress.id, safeMessage.id), !messageFromStore.seen {
                        await updateMessageSeenStatus(messageData: messageFromStore, address: safeAddress)
                    }
                }
            }
        }
    }
    @Published var selectedCompleteMessage: Message?
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
            
            try await fetchMessagesForAllAddresses()
            clearMessage()
        } catch {
            show(message: error.localizedDescription)
            //print("Error fetching addresses: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    private func fetchMessagesForAllAddresses() async throws {
        //print("Starting fetchMessagesForAllAddresses with \(addresses.count) addresses")
        
        // Create concurrent tasks but handle errors individually
        var tasks = [Task<Void, Error>]()
        
        for address in self.addresses {
            //print("Processing Address", address.address, address.isArchived, address.token?.count ?? "NA")
            
            guard !address.isArchived, let token = address.token, !token.isEmpty else {
                continue
            }
            
            tasks.append(Task {
                do {
                    await MainActor.run {
                        self.updateMessageStore(
                            for: address,
                            store: MessageStore(isFetching: true, error: nil, messages: self.messageStore[address.id]?.messages ?? [])
                        )
                    }
                    
                    let messages = try await MailTMService.fetchMessages(token: token)
                    self.updateMessageStore(for: address, store: MessageStore(isFetching: false, error: nil, messages: messages))
                    self.updateMessageIdToAddIdMap(messages, address)
                } catch {
                    //print("Error processing \(address.address): \(error)")
                }
            })
        }
        
        // Wait for all tasks to complete using TaskGroup
        await withTaskGroup(of: Void.self) { group in
            for task in tasks {
                group.addTask {
                    try? await task.value
                }
            }
        }
    }
    
    private func updateMessageIdToAddIdMap(_ messages: [Message], _ address: Address) {
        messages.forEach { message in
            self.msgIdToAddId[message.id] = address.id
        }
    }
    
    func getAddress(withID addressId: String) -> Address? {
        return addresses.first { address in
            address.id == addressId
        }
    }
    
    func getAddress(withMsgID messageId: String) -> Address? {
        return getAddress(withID: msgIdToAddId[messageId] ?? "")
    }
    
    func isAddressUnique(email: String) -> (Bool, Bool) {
        let address = addresses.first { $0.address == email }
        return (address == nil, address?.isArchived ?? false)
    }

    
    /// Refresh messages for address
    func refreshMessages(for address: Address) async {
        let messages = messageStore[address.id]?.messages ?? []
        updateMessageStore(for: address, store: MessageStore(isFetching: true, error: nil, messages: messages))
        await fetchMessages(for: address)
    }
    
    /// Get messages for accointId
    func fetchMessages(for addressId: String) async {
        if let address = getAddress(withID: addressId) {
            let messages = messageStore[address.id]?.messages ?? []
            updateMessageStore(for: address, store: MessageStore(isFetching: true, error: nil, messages: messages))
            await fetchMessages(for: address)
        }
    }
    
    /// Get messages for address
    func fetchMessages(for address: Address) async {
        guard let token = address.token, !token.isEmpty else { return }
        do {
            let messages = try await MailTMService.fetchMessages(token: token)
            self.updateMessageStore(for: address, store: MessageStore(isFetching: false, error: nil, messages: messages))
            self.updateMessageIdToAddIdMap(messages, address)
        } catch {
            self.updateMessageStore(
                for: address,
                store: MessageStore(
                    isFetching: false,
                    error: error.localizedDescription,
                    messages: messageStore[address.id]?.messages ?? []
                )
            )
        }
    }
    
    func updateMessageSelection(message: Message?) async {
        if let safeMessage = message, let safeAddress = getAddress(withID: msgIdToAddId[safeMessage.id] ?? "") {
            await MainActor.run {
                self.selectedAddress = safeAddress
                self.selectedMessage = message
            }
        }
    }
    
    func fetchCompleteMessage(of message: Message, address: Address) async {
        guard let token = address.token, !token.isEmpty else { return }
        do {
            loadingCompleteMessage = true
            defer { loadingCompleteMessage = false }
            self.selectedCompleteMessage = try await MailTMService.fetchMessage(id: message.id, token: token)
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
    
    func deleteMessage(message: Message, address: Address) async {
        guard let token = address.token, !token.isEmpty else { return }
        do {
            try await MailTMService.deleteMessage(id: message.id, token: token)
            DispatchQueue.main.async {
                guard let index = self.messageStore[address.id]?.messages.firstIndex(where: { mes in
                    mes.id == message.id
                }) else { return }
                
                self.deleteMessageFromStore(for: address, at: index)
            }
        } catch {
            self.show(message: error.localizedDescription)
        }
    }
    
    func deleteMessage(indexSet: IndexSet, address: Address) async {
        for index in indexSet {
            let message = messageStore[address.id]?.messages[index]
            if let safeMessage = message {
                await self.deleteMessage(message: safeMessage, address: address)
            }
        }
    }
    
    func updateMessageSeenStatus(messageData: Message, address: Address) async {
        guard let token = address.token, !token.isEmpty else {
            self.show(message: "Unauthorized access attempt: Auth Token not available")
            return
        }
        
        self.clearMessage()

        do {
            let _ = try await MailTMService.updateMessageSeenStatus(id: messageData.id, token: token, seen: !messageData.seen)
//            await self.fetchMessages(for: address.id)
            guard let index = messageStore[address.id]?.messages.firstIndex(where: { mes in
                mes.id == messageData.id
            }) else { return }
            updateMessageInStore(for: address, with: messageData.copyWith(seen: !messageData.seen), at: index)
        } catch {
            self.show(message: error.localizedDescription)
        }
    }
    
    func downloadMessageResource(message: Message, address: Address) async -> Data? {
        guard let token = address.token, !token.isEmpty else { return nil }
        
        do {
            let data: Data = try await MailTMService.fetchMessageSource(id: message.id, token: token)
            return data
        } catch {
            self.show(message: error.localizedDescription)
            return nil
        }
    }
    
    func getMessageFromStore(_ addressId: String, _ messageId: String) -> Message? {
        return messageStore[addressId]?.messages.first { mes in
            mes.id == messageId
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
    
    /// Gets a specific address by ID
//    func getAddress(withID id: String) -> Address? {
//        do {
//            let descriptor = FetchDescriptor<Address>(
//                predicate: #Predicate<Address> { address in
//                    address.id == id && !address.isDeleted
//                }
//            )
//            let results = try modelContext.fetch(descriptor)
//            return results.first
//        } catch {
//            print("Error fetching address: \(error.localizedDescription)")
//            return nil
//        }
//    }
    
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
    
    func updateMessageInStore(for address: Address, with message: Message, at index: Int) {
        guard let safeAddress = getAddress(withID: address.id),
              var store = messageStore[safeAddress.id],
              store.messages.indices.contains(index) else { return }

        store.messages[index] = message
        messageStore[safeAddress.id] = store // This triggers @Published update
        objectWillChange.send()
    }
    
    func deleteMessageFromStore(for address: Address, at index: Int) {
        guard let safeAddress = getAddress(withID: address.id),
              var store = messageStore[safeAddress.id],
              store.messages.indices.contains(index) else { return }
        // Remove the message from the address at the addressIndex in addresses array
        store.messages.remove(at: index)
        messageStore[safeAddress.id] = store // This triggers @Published update
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
