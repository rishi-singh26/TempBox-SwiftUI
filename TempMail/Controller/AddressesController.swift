//
//  AddressesController.swift
//  TempMail
//
//  Created by Rishi Singh on 01/05/25.
//

import SwiftUI
import SwiftData
import Combine
import MailTMSwift

@MainActor
class AddressesController: ObservableObject {
    static let shared = AddressesController()
    
    // SwiftData modelContainer and modelContext
    private let modelContainer: ModelContainer
    private let modelContext: ModelContext
    
    private let messageService = MTMessageService()
    private let accountService = MTAccountService()
    
    // Published properties for UI updates
    @Published var addresses: [Address] = []
    @Published var isLoading: Bool = false
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
            if let safeMessage = newValue?.data, let safeAddress = selectedAddress {
                selectedCompleteMessage = nil
                self.fetchCompleteMessage(of: safeMessage, address: safeAddress)
            }
        }
    }
    @Published var selectedCompleteMessage: CompleteMessage?
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
            Task { fetchAddresses() }
        } catch {
            fatalError("Failed to create ModelContainer: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Data Operations
    
    /// Fetches all addresses from SwiftData
    func fetchAddresses() {
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
                self.updateMessageStore(for: address, store: MessageStore(isFetching: true, error: nil, messages: address.messagesStore?.messages ?? []))
                self.fetchMessages(for: address)
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
    func fetchMessages(for addressId: String) {
        if let address = getAddress(withID: addressId) {
            fetchMessages(for: address)
        }
    }
    
    /// Get messages for address
    func fetchMessages(for address: Address) {
        guard let token = address.token else { return }
        messageService.getAllMessages(page: 1, token: token) { (result: Result<[MTMessage], MTError>) in
            switch result {
              case .success(let messages):
                var messagesArr = [Message]()
                for message in messages {
                    messagesArr.append(Message(isComplete: true, data: message))
                }
                self.updateMessageStore(for: address, store: MessageStore(isFetching: false, error: nil, messages: messagesArr))
              case .failure(let error):
                self.updateMessageStore(for: address, store: MessageStore(isFetching: false, error: error, messages: address.messagesStore?.messages ?? []))
            }
        }
    }
    
    func fetchCompleteMessage(of message: MTMessage, address: Address) {
        guard let url = URL(string: "\(baseURL)/messages/\(message.id)") else {
            self.show(message: "InvalidURL")
            return
        }
        
        guard let token = address.token, !token.isEmpty else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        loadingCompleteMessage = true
        self.clearMessage()

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.loadingCompleteMessage = false
                    self.show(message: error.localizedDescription)
                }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async {
                    self.loadingCompleteMessage = false
                    self.show(message: "NoData")
                }
                return
            }

            do {
//                print(String(data: data, encoding: .utf8) ?? "Error One")
                let message = try JSONDecoder().decode(CompleteMessage.self, from: data)
                DispatchQueue.main.async {
                    self.loadingCompleteMessage = false
                    self.selectedCompleteMessage = message
                }
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
                DispatchQueue.main.async {
                    self.loadingCompleteMessage = false
                }
            } catch {
                print(error.localizedDescription)
                DispatchQueue.main.async {
                    self.loadingCompleteMessage = false
                    self.show(message: error.localizedDescription)
                }
            }
        }.resume()
    }
    
    func loginAndSaveAddress(address: AddressData, completion: @escaping (Bool, String) -> Void) {
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
        
        let auth = MTAuth(address: address.authenticatedUser.account.address, password: address.password)
        
        self.accountService.login(using: auth) { [self] (result: Result<String, MTError>) in
            switch result {
            case .success(let token):
                newAddress.token = token
                addAddress(newAddress)
                completion(true, "Success")
            case .failure(let error):
                completion(false, handleMTError(error: error))
            }
        }
    }
    
    func deleteAddressFromServer(address: Address) {
        guard let token = address.token else { return } // handle user alert about any issues
        accountService.deleteAccount(id: address.id, token: token) { (result: Result<MTEmptyResult, MTError>) in
            if case let .failure(error) = result {
                print("Error Occurred while deleting address from mail.tm server: \(error)")
                if let _ = error.errorDescription?.contains("Invalid JWT Token") {
                    // deleting address from swiftdata because it has been deactivated from mail.tm server
                    self.permanentlyDeleteAddress(address)
                }
                return
            }
            self.permanentlyDeleteAddress(address)
        }
    }
    
    func deleteMessage(message: Message, address: Address) {
        guard let index = address.messagesStore?.messages.firstIndex(where: { mes in
            mes.id == message.id
        }) else { return }
        guard let token = address.token else { return }
        messageService.deleteMessage(id: message.id, token: token) { (result: Result<MTEmptyResult, MTError>) in
            if case let .failure(error) = result {
                print("Error Occurred: \(error)")
                return
            }
            self.deleteMessageFromStore(for: address, at: index)
        }
    }
    
    func deleteMessage(indexSet: IndexSet, address: Address) {
        for index in indexSet {
            let message = address.messagesStore?.messages[index]
            guard let id = message?.id, let token = address.token else { return }
            messageService.deleteMessage(id: id, token: token) { (result: Result<MTEmptyResult, MTError>) in
                if case let .failure(error) = result {
                    print("Error Occurred: \(error)")
                    return
                }
                self.deleteMessageFromStore(for: address, at: index)
            }
        }
    }
    
    func updateMessage(messageData: Message, address: Address, data: [String: Bool]) {
        guard let token = address.token, !token.isEmpty else {
            self.show(message: "Unauthorized access attempt: Auth Token not available")
            return
        }
        
        // Verify that the keys in data is only seen, flagged or isDeleted
        let allowedKeys: Set<String> = ["seen", "flagged", "isDeleted"]
        let invalidKeys = data.keys.filter { !allowedKeys.contains($0) }

        guard invalidKeys.isEmpty else {
            self.show(message: "Invalid keys in update: \(invalidKeys.joined(separator: ", "))")
            return
        }
        
        self.clearMessage()
        
        let url = URL(string: "\(baseURL)/messages/\(messageData.id)")!
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/merge-patch+json", forHTTPHeaderField: "Content-Type")
                
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: data, options: [])
        } catch {
            self.show(message: "Failed to encode request body")
            return // "Failed to encode request body"
        }
        
        let addressId = address.id
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.show(message: error.localizedDescription)
                }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    self.show(message: "Invalid response")
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    self.show(message: "No data received")
                }
                return
            }
            
            if (200...299).contains(httpResponse.statusCode) {
                let responseString = String(data: data, encoding: .utf8) ?? "Success but couldn't parse response"
                DispatchQueue.main.async {
                    self.fetchMessages(for: addressId)
                    self.show(message: "Success: \(responseString)")
                }
            } else {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                DispatchQueue.main.async {
                    self.show(message: "HTTP \(httpResponse.statusCode): \(errorMessage)")
                }
            }
        }.resume()
    }
    
    func downloadMessageSource(message: Message, address: Address) {
        guard let token = address.token else { return }
        messageService.getSource(id: message.id, token: token) { (result: Result<MTMessageSource, MTError>) in
            switch result {
              case .success(let messageSource):
                let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
                let fileName: String
                if message.data.subject.isEmpty {
                    fileName = "message.eml"
                } else {
                    fileName = "\(message.data.subject).eml"
                }
                let file = paths[0].appendingPathComponent(fileName)
                do {
                    try messageSource.data.write(to: file, atomically: true, encoding: String.Encoding.utf8)
                } catch {
                    print("Error occurred \(error.localizedDescription)")
                    // failed to write file – bad permissions, bad filename, missing permissions, or more likely it can't be converted to the encoding
                }
              case .failure(let error):
                print("Error occurred \(error)")
            }
        }
    }
    
    /// Add a new address from MTAccount
    func addAddress(account: MTAccount, token: String, password: String, addressName: String) {
        let newAddress = Address(
            id: account.id,
            name: addressName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : addressName,
            address: account.address,
            quota: account.quotaLimit,
            used: account.quotaUsed,
            createdAt: account.createdAt,
            updatedAt: account.updatedAt,
            token: token,
            password: password
        )
        self.addAddress(newAddress)
    }
    
    /// Adds a new address
    func addAddress(_ address: Address) {
        modelContext.insert(address)
        saveChanges()
        fetchAddresses()
    }
    
    /// Updates an existing address
    func updateAdress(_ address: Address) {
        address.updatedAt = Date.now
        saveChanges()
//        fetchAccounts()
    }
    
    /// Delete address based on its index in the list
    func deleteAddress(indexSet: IndexSet) {
        for index in indexSet {
            let address = addresses[index]
            deleteAddress(address)
        }
    }
    
    /// Delete address based on its id
    func deleteAddress(id: String) {
        let address = addresses.first { add in
            add.id == id
        }
        if let address = address {
            deleteAddress(address)
        }
    }
    
    /// Soft deletes an address
    func deleteAddress(_ address: Address) {
        address.isDeleted = true
        address.updatedAt = Date.now
        saveChanges()
        fetchAddresses()
    }
    
    /// Hard deletes an address from the database
    func permanentlyDeleteAddress(_ address: Address) {
        modelContext.delete(address)
        saveChanges()
        fetchAddresses()
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
    func toggleAddressStatus(_ address: Address) {
        address.isDisabled.toggle()
        address.updatedAt = Date.now
        saveChanges()
        fetchAddresses()
    }
    
    /// Sets an address's fetching messages status
    func updateMessageStore(for address: Address, store: MessageStore) {
        // Note: This only updates the transient property, not saved to SwiftData
        address.messagesStore = store
        // No need to save changes or refetch as this property is transient
        // Just notify observers that the address object has changed
        objectWillChange.send()
    }
    
    func updateMessageInStore(for address: Address, with message: MTMessage, at index: Int) {
        address.messagesStore?.messages[index].data = message
        address.messagesStore?.messages.remove(at: index)
        objectWillChange.send()
    }
    
    func deleteMessageFromStore(for address: Address, at index: Int) {
        address.messagesStore?.messages.remove(at: index)
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
    
    func handleMTError(error: MTError) -> String {
        switch error {
        case .networkError(let errorString):
            // Attempt to extract JSON string from the error string
            if let jsonStartRange = errorString.range(of: "{"),
               let jsonString = String(errorString[jsonStartRange.lowerBound...]).data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: jsonString) as? [String: Any],
               let message = json["message"] as? String {
                return message
            } else {
                return error.localizedDescription
            }
        default:
            return error.localizedDescription
        }
    }
}
