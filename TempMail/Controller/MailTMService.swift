//
//  MailTMService.swift
//  TempMail
//
//  Created by Rishi Singh on 10/06/25.
//

import Foundation
import Combine

@MainActor
class MailTMService {
    static private let baseURL = "https://api.mail.tm"
    static private let session = URLSession.shared
    static private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    // MARK: - Private Methods
    
    static private func createRequest(
        endpoint: String,
        method: HTTPMethod = .GET,
        token: String?,
        body: Data? = nil,
        contentType: String? = nil,
        accept: String? = nil
    ) -> URLRequest? {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue(contentType ?? "application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(accept ?? "application/json", forHTTPHeaderField: "Accept")
        
        if let safeToken = token {
            request.setValue("Bearer \(safeToken)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            request.httpBody = body
        }
        
        return request
    }
    
    static private func performRequest<T: Codable>(_ request: URLRequest, responseType: T.Type) async throws -> (T, Data) {
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw MailTMError.networkError(URLError(.badServerResponse))
            }
                        
            switch httpResponse.statusCode {
            case 200...299:
                do {
                    let decoder = JSONDecoder()
                    return (try decoder.decode(T.self, from: data), data)
                } catch {
                    throw MailTMError.decodingError(error)
                }
            case 400:
                throw MailTMError.invalidRequest
            case 401:
                throw MailTMError.authenticationRequired
            case 404:
                throw MailTMError.notFound
            case 429:
                throw MailTMError.rateLimitExceeded
            case 500...599:
                throw MailTMError.serverError
            default:
                let errorMessage = String(data: data, encoding: .utf8)
                throw MailTMError.httpError(httpResponse.statusCode, errorMessage)
            }
        } catch {
            if error is MailTMError {
                throw error
            } else {
                throw MailTMError.networkError(error)
            }
        }
    }
    
    // MARK: - Domain Methods
    
    static func fetchDomains(page: Int = 1) async throws -> [Domain] {
        guard let request = createRequest(endpoint: "/domains?page=\(page)", token: nil) else {
            throw MailTMError.invalidURL
        }

        return try await performRequest(request, responseType: [Domain].self).0
    }
    
    static func fetchDomain(token: String, id: String) async throws -> Domain {
        guard let request = createRequest(endpoint: "/domains/\(id)", token: token) else {
            throw MailTMError.invalidURL
        }
        
        return try await performRequest(request, responseType: Domain.self).0
    }
    
    // MARK: - Account Methods
    
    static func createAccount(address: String, password: String) async throws -> Account {
        let requestBody = CreateAccountRequest(address: address, password: password)
        let bodyData = try JSONEncoder().encode(requestBody)
        
        guard let request = createRequest(endpoint: "/accounts", method: .POST, token: nil, body: bodyData) else {
            throw MailTMError.invalidURL
        }
        
        return try await performRequest(request, responseType: Account.self).0
    }
    
    static func generateRandomAccount() async throws -> (account: Account, password: String) {
        // First, fetch available domains
        let domainResponse = try await fetchDomains()
        guard let firstDomain = domainResponse.first(where: { $0.isActive && !$0.isPrivate }) else {
            throw MailTMError.notFound
        }
        
        // Generate random username and password
        let username = "user\(Int.random(in: 100000...999999))"
        let password = generateRandomPassword()
        let address = "\(username)@\(firstDomain.domain)"
        
        let account = try await createAccount(address: address, password: password)
        return (account, password)
    }
    
    static private func generateRandomPassword() -> String {
        let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*"
        return String((0..<12).map { _ in characters.randomElement()! })
    }
    
    static func authenticate(address: String, password: String) async throws -> TokenResponse {
        let requestBody = TokenRequest(address: address, password: password)
        let bodyData = try JSONEncoder().encode(requestBody)
        
        guard let request = createRequest(endpoint: "/token", method: .POST, token: nil, body: bodyData) else {
            throw MailTMError.invalidURL
        }
        
        return try await performRequest(request, responseType: TokenResponse.self).0
    }
    
    static func fetchAccount(id: String, token: String) async throws -> Account {
        guard let request = createRequest(endpoint: "/accounts/\(id)", token: token) else {
            throw MailTMError.invalidURL
        }
        
        return try await performRequest(request, responseType: Account.self).0
    }
    
    static func deleteAccount(id: String, token: String) async throws {
        guard let request = createRequest(endpoint: "/accounts/\(id)", method: .DELETE, token: token) else {
            throw MailTMError.invalidURL
        }
        
        _ = try await performRequest(request, responseType: EmptyResponse.self)
    }
    
    // MARK: - Message Methods
    
    static func fetchMessages(token: String, page: Int = 1) async throws -> [Message] {
        guard let request = createRequest(endpoint: "/messages?page=\(page)", token: token) else {
            throw MailTMError.invalidURL
        }
        
        return try await performRequest(request, responseType: [Message].self).0
    }
    
    static func fetchMessage(id: String, token: String) async throws -> Message {
        guard let request = createRequest(endpoint: "/messages/\(id)", token: token) else {
            throw MailTMError.invalidURL
        }
        
        return try await performRequest(request, responseType: Message.self).0
    }
    
    static func updateMessageSeenStatus(id: String, token: String, seen: Bool) async throws -> MarkAsReadResponse {
        let requestData = try JSONSerialization.data(withJSONObject: ["seen": seen], options: [])
        
        guard let request = createRequest(endpoint: "/messages/\(id)", method: .PATCH, token: token, body: requestData, contentType: "application/merge-patch+json") else {
            throw MailTMError.invalidURL
        }
        
        return try await performRequest(request, responseType: MarkAsReadResponse.self).0
    }
    
    static func deleteMessage(id: String, token: String) async throws {
        guard let request = createRequest(endpoint: "/messages/\(id)", method: .DELETE, token: token) else {
            throw MailTMError.invalidURL
        }
        
        _ = try await performRequest(request, responseType: EmptyResponse.self)
    }
    
    static func fetchMessageSource(id: String, token: String) async throws -> (Message, Data) {
        guard let request = createRequest(endpoint: "/sources/\(id)", token: token) else {
            throw MailTMError.invalidURL
        }
        
        return try await performRequest(request, responseType: Message.self)
    }
    
    // MARK: - Utility Methods
    
    static func setupQuickAccount() async throws -> String {
        let (account, password) = try await generateRandomAccount()
        _ = try await authenticate(address: account.address, password: password)
        return password
    }
}

// MARK: - Helper Types

enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PATCH = "PATCH"
    case DELETE = "DELETE"
}

struct EmptyResponse: Codable {}

enum MailTMError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingError(Error)
    case networkError(Error)
    case httpError(Int, String?)
    case authenticationRequired
    case rateLimitExceeded
    case invalidRequest
    case notFound
    case serverError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .httpError(let code, let message):
            return "HTTP Error \(code): \(message ?? "Unknown error")"
        case .authenticationRequired:
            return "Authentication required"
        case .rateLimitExceeded:
            return "Rate limit exceeded. Please wait before making another request."
        case .invalidRequest:
            return "Invalid request"
        case .notFound:
            return "Resource not found"
        case .serverError:
            return "Server error"
        }
    }
}
