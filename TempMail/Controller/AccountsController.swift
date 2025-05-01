//
//  AccountsController.swift
//  TempMail
//
//  Created by Rishi Singh on 01/05/25.
//

import SwiftUI
import SwiftData
import Combine
import MailTMSwift

@MainActor
class AccountsController: ObservableObject {
    static let shared = AccountsController()
    
    // SwiftData modelContainer and modelContext
    private let modelContainer: ModelContainer
    private let modelContext: ModelContext
    
    private let messageService = MTMessageService()
    private let accountService = MTAccountService()
    
    // Published properties for UI updates
    @Published var accounts: [Account] = []
    @Published var isLoading: Bool = false
    @Published var error: Error?
    
    @Published var selectedAccount: Account?
    @Published var selectedMessage: Message?
    
    // We will fetch complete message when a message from the list is selected
    @Published var loadingCompleteMessage = false
    
    // MARK: - Initialization
    
    init() {
        // Set up SwiftData container
        do {
            let schema = Schema([Account.self])
            let configuration = ModelConfiguration(isStoredInMemoryOnly: false)
            modelContainer = try ModelContainer(for: schema, configurations: [configuration])
            modelContext = modelContainer.mainContext
            
            // Load accounts on initialization
            Task { fetchAccounts() }
        } catch {
            fatalError("Failed to create ModelContainer: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Data Operations
    
    /// Fetches all accounts from SwiftData
    func fetchAccounts() {
        isLoading = true
        
        do {
            let descriptor = FetchDescriptor<Account>(
                predicate: #Predicate<Account> { account in
                    !account.isDeleted
                },
                sortBy: [SortDescriptor(\Account.name)]
            )
            accounts = try modelContext.fetch(descriptor)
            error = nil
            
            /// Fetch messages for each account
            for account in self.accounts {
                self.updateMessageStore(for: account, store: MessageStore(isFetching: true, error: nil, messages: account.messagesStore?.messages ?? []))
                self.fetchMessages(for: account)
            }
        } catch {
            self.error = error
            print("Error fetching accounts: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    func fetchMessages(for account: Account) {
        guard let token = account.token else { return }
        messageService.getAllMessages(token: token) { (result: Result<[MTMessage], MTError>) in
            switch result {
              case .success(let messages):
                var messagesArr = [Message]()
                for message in messages {
                    messagesArr.append(Message(isComplete: true, data: message))
                }
                self.updateMessageStore(for: account, store: MessageStore(isFetching: false, error: nil, messages: messagesArr))
              case .failure(let error):
                self.updateMessageStore(for: account, store: MessageStore(isFetching: false, error: error, messages: account.messagesStore?.messages ?? []))
            }
        }
    }
    
    func fetchCompleteMessage(of message: MTMessage, account: Account) {
        guard let token = account.token else { return } // handle user alert about any issues
        loadingCompleteMessage = true
        messageService.getMessage(id: message.id, token: token) { (result: Result<MTMessage, MTError>) in
            switch result {
            case .success(let message):
                self.selectedMessage = Message(isComplete: true, data: message)
            case .failure(let error):
                print("Error in getting complete message \(error)")
            }
            self.loadingCompleteMessage = false
        }
    }
    
    func deleteAccountFromServer(account: Account) {
        guard let token = account.token else { return } // handle user alert about any issues
        accountService.deleteAccount(id: account.id, token: token) { (result: Result<MTEmptyResult, MTError>) in
            if case let .failure(error) = result {
                print("Error Occurred while deleting account from mail.tm server: \(error)")
                if let _ = error.errorDescription?.contains("Invalid JWT Token") {
                    // deleting account from coredata because it has been deactivated from mail.tm server
                    self.permanentlyDeleteAccount(account)
                }
                return
            }
            self.permanentlyDeleteAccount(account)
        }
    }
    
    func deleteMessage(message: Message, account: Account) {
        guard let index = account.messagesStore?.messages.firstIndex(where: { mes in
            mes.id == message.id
        }) else { return }
        guard let token = account.token else { return }
        messageService.deleteMessage(id: message.id, token: token) { (result: Result<MTEmptyResult, MTError>) in
            if case let .failure(error) = result {
                print("Error Occurred: \(error)")
                return
            }
            self.deleteMessageFromStore(for: account, at: index)
        }
    }
    
    func deleteMessage(indexSet: IndexSet, account: Account) {
        for index in indexSet {
            let message = account.messagesStore?.messages[index]
            guard let id = message?.id, let token = account.token else { return }
            messageService.deleteMessage(id: id, token: token) { (result: Result<MTEmptyResult, MTError>) in
                if case let .failure(error) = result {
                    print("Error Occurred: \(error)")
                    return
                }
                self.deleteMessageFromStore(for: account, at: index)
            }
        }
    }
    
    func markMessageAsRead(messageData: Message, account: Account, seen: Bool = true) {
        guard let messageIndex = account.messagesStore?.messages.firstIndex(where: { mes in
            mes.id == messageData.id
        }) else { return }
        guard let token = account.token else { return }
        messageService.markMessageAs(id: messageData.id, seen: seen, token: token) { (result: Result<MTMessage, MTError>) in
            switch result {
              case .success(let message):
                self.updateMessageInStore(for: account, with: message, at: messageIndex)
              case .failure(let error):
                print("Error occurred \(error)")
            }
        }
    }
    
    func downloadMessageSource(message: Message, account: Account) {
        guard let token = account.token else { return }
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
    
    /// Add a new account from MTAccount
    func addAccount(account: MTAccount, token: String, password: String, accountName: String) {
        let newAccount = Account(
            id: account.id,
            name: accountName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : accountName,
            address: account.address,
            quota: account.quotaLimit,
            used: account.quotaUsed,
            createdAt: account.createdAt,
            updatedAt: account.updatedAt,
            token: token,
            password: password
        )
        self.addAccount(newAccount)
    }
    
    /// Adds a new account
    func addAccount(_ account: Account) {
        modelContext.insert(account)
        saveChanges()
        fetchAccounts()
    }
    
    /// Updates an existing account
    func updateAccount(_ account: Account) {
        account.updatedAt = Date.now
        saveChanges()
//        fetchAccounts()
    }
    
    /// Delete account based on its index in the list
    func deleteAccount(indexSet: IndexSet) {
        for index in indexSet {
            let account = accounts[index]
            deleteAccount(account)
        }
    }
    
    /// Delete account based on its id
    func deleteAccount(id: String) {
        let account = accounts.first { acc in
            acc.id == id
        }
        if let account = account {
            deleteAccount(account)
        }
    }
    
    /// Soft deletes an account
    func deleteAccount(_ account: Account) {
        account.isDeleted = true
        account.updatedAt = Date.now
        saveChanges()
        fetchAccounts()
    }
    
    /// Hard deletes an account from the database
    func permanentlyDeleteAccount(_ account: Account) {
        modelContext.delete(account)
        saveChanges()
        fetchAccounts()
    }
    
    /// Gets a specific account by ID
    func getAccount(withID id: String) -> Account? {
        do {
            let descriptor = FetchDescriptor<Account>(
                predicate: #Predicate<Account> { account in
                    account.id == id && !account.isDeleted
                }
            )
            let results = try modelContext.fetch(descriptor)
            return results.first
        } catch {
            print("Error fetching account: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Toggles the disabled status of an account
    func toggleAccountStatus(_ account: Account) {
        account.isDisabled.toggle()
        account.updatedAt = Date.now
        saveChanges()
        fetchAccounts()
    }
    
    /// Sets an account's fetching messages status
    func updateMessageStore(for account: Account, store: MessageStore) {
        // Note: This only updates the transient property, not saved to SwiftData
        account.messagesStore = store
        // No need to save changes or refetch as this property is transient
        // Just notify observers that the account object has changed
        objectWillChange.send()
    }
    
    func updateMessageInStore(for account: Account, with message: MTMessage, at index: Int) {
        account.messagesStore?.messages[index].data = message
        account.messagesStore?.messages.remove(at: index)
        objectWillChange.send()
    }
    
    func deleteMessageFromStore(for account: Account, at index: Int) {
        account.messagesStore?.messages.remove(at: index)
        objectWillChange.send()
    }
    
    // MARK: - Helper Methods
    
    /// Saves changes to SwiftData
    private func saveChanges() {
        do {
            try modelContext.save()
        } catch {
            self.error = error
            print("Error saving context: \(error.localizedDescription)")
        }
    }
    
    /// Clears any error message
    func clearError() {
        error = nil
    }
}
