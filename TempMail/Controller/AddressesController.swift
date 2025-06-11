//
//  AddressesController.swift
//  TempMail
//
//  Created by Rishi Singh on 01/05/25.
//

import SwiftUI
import SwiftData
import Combine

@MainActor
class AddressesController: ObservableObject {
    static let shared = AddressesController()
    
    // SwiftData modelContainer and modelContext
    private let modelContainer: ModelContainer
    private let modelContext: ModelContext
        
    // Published properties for UI updates
    @Published var addresses: [Address] = []
    @Published var isLoading: Bool = false
    @Published var messageStore: [String: MessageStore] = [:]
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
            if let safeMessage = newValue, let safeAddress = selectedAddress {
                selectedCompleteMessage = nil
                Task {
                    await fetchCompleteMessage(of: safeMessage, address: safeAddress)
                }
            }
        }
    }
    @Published var selectedCompleteMessage: Message?
    // We will fetch complete message when a message from the list is selected
    @Published var loadingCompleteMessage = false
    
    private var cancellables = Set<AnyCancellable>()
    private let baseURL = "https://api.mail.tm"
    
    // MARK: - Initialization
    
    init() {
        // Set up SwiftData container
        do {
            let schema = Schema([Address.self])
            let configuration = ModelConfiguration(isStoredInMemoryOnly: false)
            modelContainer = try ModelContainer(for: schema, configurations: [configuration])
            modelContext = modelContainer.mainContext
            
            // Load addresses on initialization
            Task { await fetchAddresses() }
        } catch {
            fatalError("Failed to create ModelContainer: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Data Operations
    
    /// Fetches all addresses from SwiftData
    func fetchAddresses() async {
        isLoading = true
        
        do {
            let descriptor = FetchDescriptor<Address>(
                predicate: #Predicate<Address> { address in
                    !address.isDeleted
                },
                sortBy: [SortDescriptor(\Address.updatedAt, order: .reverse)]
            )
            addresses = try modelContext.fetch(descriptor)
            self.clearMessage()
            
            /// Fetch messages for each address
            for address in self.addresses {
                self.updateMessageStore(for: address, store: MessageStore(isFetching: true, error: nil, messages: messageStore[address.id]?.messages ?? []))
                await self.fetchMessages(for: address)
            }
        } catch {
            self.show(message: error.localizedDescription)
            print("Error fetching addresses: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    func getAddress(withID addressId: String) -> Address? {
        return addresses.first { address in
            address.id == addressId
        }
    }
    
    /// Get messages for accointId
    func fetchMessages(for addressId: String) async {
        if let address = getAddress(withID: addressId) {
            await fetchMessages(for: address)
        }
    }
    
    /// Get messages for address
    func fetchMessages(for address: Address) async {
        guard let token = address.token, !token.isEmpty else { return }
        do {
            let messages = try await MailTMService.fetchMessages(token: token)
            self.updateMessageStore(for: address, store: MessageStore(isFetching: false, error: nil, messages: messages))
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
    
    func fetchCompleteMessage(of message: Message, address: Address) async {
        guard let token = address.token, !token.isEmpty else { return }
        do {
            loadingCompleteMessage = true
            defer { loadingCompleteMessage = false }
            let message = try await MailTMService.fetchMessage(id: message.id, token: token)
            self.selectedCompleteMessage = message
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
    
    func loginAndSaveAddress(address: AddressData, completion: @escaping (Bool, String) -> Void) async {
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
            completion(true, "Success")
        } catch {
            completion(false, error.localizedDescription)
            self.show(message: error.localizedDescription)
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
            
            guard let index = messageStore[address.id]?.messages.firstIndex(where: { mes in
                mes.id == message.id
            }) else { return }
            self.deleteMessageFromStore(for: address, at: index)
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
    
    func updateMessageSeenStatus(messageData: Message, address: Address, seen: Bool) async {
        guard let token = address.token, !token.isEmpty else {
            self.show(message: "Unauthorized access attempt: Auth Token not available")
            return
        }
        
        self.clearMessage()

        do {
            let _ = try await MailTMService.updateMessageSeenStatus(id: messageData.id, token: token, seen: seen)
//            await self.fetchMessages(for: address.id)
            guard let index = messageStore[address.id]?.messages.firstIndex(where: { mes in
                mes.id == messageData.id
            }) else { return }
            updateMessageInStore(for: address, with: messageData.copyWith(seen: seen), at: index)
        } catch {
            self.show(message: error.localizedDescription)
        }
    }
    
    func downloadMessageSource(message: Message, address: Address) async {
        guard let token = address.token, !token.isEmpty else { return }
        
        do {
            let (_, data) = try await MailTMService.fetchMessageSource(id: message.id, token: token)
            
            let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            
            let fileName: String
            if message.subject.isEmpty {
                fileName = "message.eml"
            } else {
                fileName = "\(message.subject).eml"
            }
            
            let file = paths[0].appendingPathComponent(fileName)
            
            do {
                try data.write(to: file)
            } catch {
                print("Error occurred \(error.localizedDescription)")
                // failed to write file – bad permissions, bad filename, missing permissions, or more likely it can't be converted to the encoding
            }
        } catch {
            self.show(message: error.localizedDescription)
        }
    }
    
    /// Add a new address from MTAccount
    func addAddress(account: Account, token: String, password: String, addressName: String) async {
        let newAddress = Address(
            id: account.id,
            name: addressName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : addressName,
            address: account.address,
            quota: account.quota,
            used: account.used,
            createdAt: account.createdAtDate,
            updatedAt: account.updatedAtDate,
            token: token,
            password: password
        )
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
    
    /// Toggles the disabled status of an address
    func toggleAddressStatus(_ address: Address) async {
        address.isDisabled.toggle()
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
        // Find address index
        guard let addressIndex: Array<Address>.Index = addresses.firstIndex(where: { addr in
            addr.id == address.id
        }) else { return }
        // Remove the message from the address at the addressIndex in addresses array
        messageStore[addresses[addressIndex].id]?.messages.remove(at: index)
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
