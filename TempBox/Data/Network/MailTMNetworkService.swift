//
//  MailTMNetworkService.swift
//  TempBox
//
//  Created by Rishi Singh on 06/04/26.
//

import Foundation

// NOT @MainActor — HTTP work runs on URLSession threads
final class MailTMNetworkService: MailTMNetworkServiceProtocol {
    private let baseURL = "https://api.mail.tm"
    private let session: URLSession
    public static let shared = MailTMNetworkService()

    init(session: URLSession = .shared) {
        self.session = session
    }

    // MARK: - Private Methods

    private func createRequest(
        endpoint: String,
        method: HTTPMethod = .GET,
        token: String?,
        body: Data? = nil,
        contentType: String? = nil,
        accept: String? = nil
    ) -> URLRequest? {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else { return nil }

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

    private func performRequest<T: Codable>(_ request: URLRequest, responseType: T.Type) async throws -> (T, Data) {
        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw MailTMError.networkError(URLError(.badServerResponse))
            }

            switch httpResponse.statusCode {
            case 200...299:
                do {
                    let decoder = JSONDecoder()
                    let decodableData = data.isEmpty ? "{}".data(using: .utf8)! : data
                    return (try decoder.decode(T.self, from: decodableData), data)
                } catch {
                    throw MailTMError.decodingError(error)
                }
            case 400:
                throw MailTMError.invalidRequest
            case 401:
                throw MailTMError.authenticationRequired
            case 404:
                throw MailTMError.notFound
            case 422:
                throw MailTMError.addressAlredyInUse
            case 429:
                try await Task.sleep(for: .seconds(1.5))
                return try await performRequest(request, responseType: responseType)
            case 500...599:
                throw MailTMError.serverError
            default:
                let errorMessage = String(data: data, encoding: .utf8) ?? "No error message"
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

    func fetchDomains(page: Int = 1) async throws -> [Domain] {
        guard let request = createRequest(endpoint: "/domains?page=\(page)", token: nil) else {
            throw MailTMError.invalidURL
        }
        return try await performRequest(request, responseType: [Domain].self).0
    }

    // MARK: - Account Methods

    func createAccount(address: String, password: String) async throws -> Account {
        let requestBody = CreateAccountRequest(address: address, password: password)
        let bodyData = try JSONEncoder().encode(requestBody)
        guard let request = createRequest(endpoint: "/accounts", method: .POST, token: nil, body: bodyData) else {
            throw MailTMError.invalidURL
        }
        return try await performRequest(request, responseType: Account.self).0
    }

    func generateRandomAccount() async throws -> (Account, String) {
        let domainResponse = try await fetchDomains()
        guard let firstDomain = domainResponse.first(where: { $0.isActive && !$0.isPrivate }) else {
            throw MailTMError.notFound
        }

        let username = String.generateUsername()
        let password = String.generatePassword(of: 12, useUpperCase: true, useNumbers: true, useSpecialCharacters: true)
        let address = "\(username)@\(firstDomain.domain)"

        let account = try await createAccount(address: address, password: password)
        return (account, password)
    }

    func authenticate(address: String, password: String) async throws -> TokenResponse {
        let requestBody = TokenRequest(address: address, password: password)
        let bodyData = try JSONEncoder().encode(requestBody)
        guard let request = createRequest(endpoint: "/token", method: .POST, token: nil, body: bodyData) else {
            throw MailTMError.invalidURL
        }
        return try await performRequest(request, responseType: TokenResponse.self).0
    }

    func fetchAccount(id: String, token: String) async throws -> Account {
        guard let request = createRequest(endpoint: "/accounts/\(id)", token: token) else {
            throw MailTMError.invalidURL
        }
        return try await performRequest(request, responseType: Account.self).0
    }

    func deleteAccount(id: String, token: String) async throws {
        guard let request = createRequest(endpoint: "/accounts/\(id)", method: .DELETE, token: token) else {
            throw MailTMError.invalidURL
        }
        _ = try await performRequest(request, responseType: EmptyResponse.self)
    }

    // MARK: - Message Methods

    func fetchMessages(token: String, page: Int = 1) async throws -> [APIMessage] {
        guard let request = createRequest(endpoint: "/messages?page=\(page)", token: token) else {
            throw MailTMError.invalidURL
        }
        return try await performRequest(request, responseType: [APIMessage].self).0
    }

    func fetchMessage(id: String, token: String) async throws -> APIMessage {
        guard let request = createRequest(endpoint: "/messages/\(id)", token: token) else {
            throw MailTMError.invalidURL
        }
        return try await performRequest(request, responseType: APIMessage.self).0
    }

    func updateMessageSeenStatus(id: String, token: String, seen: Bool) async throws -> MarkAsReadResponse {
        let requestData = try JSONSerialization.data(withJSONObject: ["seen": seen], options: [])
        guard let request = createRequest(
            endpoint: "/messages/\(id)",
            method: .PATCH,
            token: token,
            body: requestData,
            contentType: "application/merge-patch+json"
        ) else {
            throw MailTMError.invalidURL
        }
        return try await performRequest(request, responseType: MarkAsReadResponse.self).0
    }

    func deleteMessage(id: String, token: String) async throws {
        guard let request = createRequest(endpoint: "/messages/\(id)", method: .DELETE, token: token) else {
            throw MailTMError.invalidURL
        }
        _ = try await performRequest(request, responseType: EmptyResponse.self)
    }

    func fetchMessageSource(id: String, token: String) async throws -> (APIMessage, Data) {
        guard let request = createRequest(endpoint: "/sources/\(id)", token: token) else {
            throw MailTMError.invalidURL
        }
        return try await performRequest(request, responseType: APIMessage.self)
    }

    func downloadMessageEML(id: String, token: String) async throws -> Data {
        do {
            guard let request = createRequest(endpoint: "/messages/\(id)/download", token: token) else {
                throw MailTMError.invalidURL
            }

            let (data, response): (Data, URLResponse) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw MailTMError.notFound
            }

            switch httpResponse.statusCode {
            case 200...299:
                return data
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
                let errorMessage = String(data: data, encoding: .utf8) ?? "No error message"
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

    func downloadAttachment(messageId: String, attachment: Attachment, token: String) async throws -> AttachmentDownload {
        guard let url = URL(string: "\(baseURL)/messages/\(messageId)/attachment/\(attachment.id)") else {
            throw MailTMError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw MailTMError.networkError(URLError(.badServerResponse))
            }

            switch httpResponse.statusCode {
            case 200...299:
                let tempDirectory = FileManager.default.temporaryDirectory
                let tempFileURL = tempDirectory.appendingPathComponent(attachment.filename)
                try data.write(to: tempFileURL)
                return AttachmentDownload(
                    fileURL: tempFileURL,
                    fileData: data,
                    filename: attachment.filename,
                    contentType: attachment.contentType,
                    messageId: messageId,
                    attachmentId: attachment.id
                )
            case 401:
                throw MailTMError.authenticationRequired
            case 404:
                throw MailTMError.notFound
            case 429:
                throw MailTMError.rateLimitExceeded
            default:
                throw MailTMError.httpError(httpResponse.statusCode, "Failed to download attachment")
            }
        } catch {
            if error is MailTMError {
                throw error
            } else {
                throw MailTMError.networkError(error)
            }
        }
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
    case addressAlredyInUse
    
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
        case .addressAlredyInUse:
            return "This address is already in use, you can login to this address."
        }
    }
}
