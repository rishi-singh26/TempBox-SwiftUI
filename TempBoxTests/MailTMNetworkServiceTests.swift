//
//  MailTMNetworkServiceTests.swift
//  TempBoxTests
//

import XCTest
@testable import TempBox

final class MailTMNetworkServiceTests: XCTestCase {

    private var sut: MailTMNetworkService!

    override func setUp() {
        super.setUp()
        MockURLProtocol.requestHandler = nil
        sut = MailTMNetworkService(session: MockURLProtocol.makeSession())
    }

    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        sut = nil
        super.tearDown()
    }

    // MARK: - JSON Fixtures

    private func domainJSON(_ id: String = "dom-1", domain: String = "test.io", isActive: Bool = true, isPrivate: Bool = false) -> Data {
        let json = """
        [{"id":"\(id)","domain":"\(domain)","isActive":\(isActive),"isPrivate":\(isPrivate),"createdAt":"2024-01-01T00:00:00+00:00","updatedAt":"2024-01-01T00:00:00+00:00"}]
        """
        return json.data(using: .utf8)!
    }

    private func accountJSON(_ id: String = "acct-1", address: String = "user@test.io") -> Data {
        let json = """
        {"id":"\(id)","address":"\(address)","quota":40000000,"used":0,"isDisabled":false,"isDeleted":false,"createdAt":"2024-01-01T00:00:00+00:00","updatedAt":"2024-01-01T00:00:00+00:00"}
        """
        return json.data(using: .utf8)!
    }

    private func tokenJSON(id: String = "tok-1", token: String = "bearer_xyz") -> Data {
        """
        {"id":"\(id)","token":"\(token)"}
        """.data(using: .utf8)!
    }

    private func messageJSON(id: String = "msg-1", seen: Bool = false) -> Data {
        let json = """
        {"id":"\(id)","accountId":"acct-1","msgid":"<msgid@test.io>","from":{"name":"Sender","address":"from@test.io"},"to":[{"name":"","address":"to@test.io"}],"subject":"Hello","seen":\(seen),"isDeleted":false,"hasAttachments":false,"size":512,"downloadUrl":"/messages/\(id)/download","sourceUrl":"/sources/\(id)","createdAt":"2024-01-15T10:00:00Z","updatedAt":"2024-01-15T10:00:00Z"}
        """
        return json.data(using: .utf8)!
    }

    private func messagesJSON(count: Int = 1) -> Data {
        let messages = (0..<count).map { i in
            """
            {"id":"msg-\(i)","accountId":"acct-1","msgid":"<msgid\(i)@test.io>","from":{"name":"Sender","address":"from@test.io"},"to":[{"name":"","address":"to@test.io"}],"subject":"Subject \(i)","seen":false,"isDeleted":false,"hasAttachments":false,"size":256,"downloadUrl":"/messages/msg-\(i)/download","sourceUrl":"/sources/msg-\(i)","createdAt":"2024-01-15T10:00:00Z","updatedAt":"2024-01-15T10:00:00Z"}
            """
        }.joined(separator: ",")
        return "[\(messages)]".data(using: .utf8)!
    }

    // MARK: - fetchDomains

    func testFetchDomains_success_returnsDomains() async throws {
        MockURLProtocol.requestHandler = { _ in
            (.init(url: URL(string: "https://api.mail.tm/domains?page=1")!, statusCode: 200, httpVersion: nil, headerFields: nil)!, self.domainJSON())
        }
        let domains = try await sut.fetchDomains(page: 1)
        XCTAssertEqual(domains.count, 1)
        XCTAssertEqual(domains.first?.domain, "test.io")
        XCTAssertTrue(domains.first?.isActive ?? false)
    }

    func testFetchDomains_setsCorrectEndpoint() async throws {
        var capturedRequest: URLRequest?
        MockURLProtocol.requestHandler = { request in
            capturedRequest = request
            return (MockURLProtocol.response(statusCode: 200), self.domainJSON())
        }
        _ = try await sut.fetchDomains(page: 2)
        XCTAssertTrue(capturedRequest?.url?.absoluteString.contains("page=2") ?? false)
    }

    func testFetchDomains_decodingError_throwsDecodingError() async {
        MockURLProtocol.stub(statusCode: 200, data: "invalid json".data(using: .utf8)!)
        do {
            _ = try await sut.fetchDomains()
            XCTFail("Expected error")
        } catch let error as MailTMError {
            if case .decodingError = error { /* pass */ } else {
                XCTFail("Expected .decodingError, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testFetchDomains_serverError_throwsServerError() async {
        MockURLProtocol.stub(statusCode: 500)
        do {
            _ = try await sut.fetchDomains()
            XCTFail("Expected error")
        } catch let error as MailTMError {
            if case .serverError = error { /* pass */ } else {
                XCTFail("Expected .serverError, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - createAccount

    func testCreateAccount_success_returnsAccount() async throws {
        MockURLProtocol.stub(statusCode: 201, data: accountJSON("acct-99", address: "new@test.io"))
        let account = try await sut.createAccount(address: "new@test.io", password: "pass")
        XCTAssertEqual(account.id, "acct-99")
        XCTAssertEqual(account.address, "new@test.io")
    }

    func testCreateAccount_usesPostMethod() async throws {
        var capturedRequest: URLRequest?
        MockURLProtocol.requestHandler = { request in
            capturedRequest = request
            return (MockURLProtocol.response(statusCode: 201), self.accountJSON())
        }
        _ = try await sut.createAccount(address: "a@test.io", password: "p")
        XCTAssertEqual(capturedRequest?.httpMethod, "POST")
    }

    func testCreateAccount_conflict_throwsAddressAlreadyInUse() async {
        MockURLProtocol.stub(statusCode: 422)
        do {
            _ = try await sut.createAccount(address: "taken@test.io", password: "p")
            XCTFail("Expected error")
        } catch let error as MailTMError {
            if case .addressAlredyInUse = error { /* pass */ } else {
                XCTFail("Expected .addressAlredyInUse, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - authenticate

    func testAuthenticate_success_returnsToken() async throws {
        MockURLProtocol.stub(statusCode: 200, data: tokenJSON(token: "tok_abc"))
        let response = try await sut.authenticate(address: "user@test.io", password: "pass")
        XCTAssertEqual(response.token, "tok_abc")
    }

    func testAuthenticate_usesPostMethod() async throws {
        var capturedRequest: URLRequest?
        MockURLProtocol.requestHandler = { request in
            capturedRequest = request
            return (MockURLProtocol.response(statusCode: 200), self.tokenJSON())
        }
        _ = try await sut.authenticate(address: "a@test.io", password: "p")
        XCTAssertEqual(capturedRequest?.httpMethod, "POST")
    }

    func testAuthenticate_unauthorized_throwsAuthRequired() async {
        MockURLProtocol.stub(statusCode: 401)
        do {
            _ = try await sut.authenticate(address: "user@test.io", password: "wrong")
            XCTFail("Expected error")
        } catch let error as MailTMError {
            if case .authenticationRequired = error { /* pass */ } else {
                XCTFail("Expected .authenticationRequired, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - fetchAccount

    func testFetchAccount_success_returnsAccount() async throws {
        MockURLProtocol.stub(statusCode: 200, data: accountJSON("acct-42"))
        let account = try await sut.fetchAccount(id: "acct-42", token: "tok")
        XCTAssertEqual(account.id, "acct-42")
    }

    func testFetchAccount_notFound_throwsNotFound() async {
        MockURLProtocol.stub(statusCode: 404)
        do {
            _ = try await sut.fetchAccount(id: "ghost", token: "tok")
            XCTFail("Expected error")
        } catch let error as MailTMError {
            if case .notFound = error { /* pass */ } else {
                XCTFail("Expected .notFound, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testFetchAccount_setsAuthorizationHeader() async throws {
        var capturedRequest: URLRequest?
        MockURLProtocol.requestHandler = { request in
            capturedRequest = request
            return (MockURLProtocol.response(statusCode: 200), self.accountJSON())
        }
        _ = try await sut.fetchAccount(id: "acct-1", token: "my_token")
        XCTAssertEqual(capturedRequest?.value(forHTTPHeaderField: "Authorization"), "Bearer my_token")
    }

    // MARK: - deleteAccount

    func testDeleteAccount_success_doesNotThrow() async throws {
        MockURLProtocol.stub(statusCode: 204)
        try await sut.deleteAccount(id: "acct-1", token: "tok")
    }

    func testDeleteAccount_usesDeleteMethod() async throws {
        var capturedRequest: URLRequest?
        MockURLProtocol.requestHandler = { request in
            capturedRequest = request
            return (MockURLProtocol.response(statusCode: 204), Data())
        }
        try await sut.deleteAccount(id: "acct-1", token: "tok")
        XCTAssertEqual(capturedRequest?.httpMethod, "DELETE")
    }

    func testDeleteAccount_unauthorized_throwsAuthRequired() async {
        MockURLProtocol.stub(statusCode: 401)
        do {
            try await sut.deleteAccount(id: "acct-1", token: "bad")
            XCTFail("Expected error")
        } catch let error as MailTMError {
            if case .authenticationRequired = error { /* pass */ } else {
                XCTFail("Expected .authenticationRequired, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - fetchMessages

    func testFetchMessages_success_returnsMessages() async throws {
        MockURLProtocol.stub(statusCode: 200, data: messagesJSON(count: 3))
        let messages = try await sut.fetchMessages(token: "tok", page: 1)
        XCTAssertEqual(messages.count, 3)
    }

    func testFetchMessages_empty_returnsEmptyArray() async throws {
        MockURLProtocol.stub(statusCode: 200, data: "[]".data(using: .utf8)!)
        let messages = try await sut.fetchMessages(token: "tok", page: 1)
        XCTAssertTrue(messages.isEmpty)
    }

    func testFetchMessages_setsCorrectPageQueryParam() async throws {
        var capturedURL: URL?
        MockURLProtocol.requestHandler = { request in
            capturedURL = request.url
            return (MockURLProtocol.response(statusCode: 200), self.messagesJSON())
        }
        _ = try await sut.fetchMessages(token: "tok", page: 5)
        XCTAssertTrue(capturedURL?.absoluteString.contains("page=5") ?? false)
    }

    // MARK: - fetchMessage

    func testFetchMessage_success_returnsMessage() async throws {
        MockURLProtocol.stub(statusCode: 200, data: messageJSON(id: "msg-X"))
        let message = try await sut.fetchMessage(id: "msg-X", token: "tok")
        XCTAssertEqual(message.id, "msg-X")
    }

    func testFetchMessage_notFound_throwsNotFound() async {
        MockURLProtocol.stub(statusCode: 404)
        do {
            _ = try await sut.fetchMessage(id: "ghost", token: "tok")
            XCTFail("Expected error")
        } catch let error as MailTMError {
            if case .notFound = error { /* pass */ } else {
                XCTFail("Expected .notFound, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - updateMessageSeenStatus

    func testUpdateMessageSeenStatus_success_returnsSeenTrue() async throws {
        let responseData = """
        {"seen":true}
        """.data(using: .utf8)!
        MockURLProtocol.stub(statusCode: 200, data: responseData)
        let result = try await sut.updateMessageSeenStatus(id: "msg-1", token: "tok", seen: true)
        XCTAssertTrue(result.seen)
    }

    func testUpdateMessageSeenStatus_usesPatchMethod() async throws {
        var capturedRequest: URLRequest?
        MockURLProtocol.requestHandler = { request in
            capturedRequest = request
            return (MockURLProtocol.response(statusCode: 200), """
            {"seen":true}
            """.data(using: .utf8)!)
        }
        _ = try await sut.updateMessageSeenStatus(id: "msg-1", token: "tok", seen: true)
        XCTAssertEqual(capturedRequest?.httpMethod, "PATCH")
    }

    func testUpdateMessageSeenStatus_setsMergePatchContentType() async throws {
        var capturedRequest: URLRequest?
        MockURLProtocol.requestHandler = { request in
            capturedRequest = request
            return (MockURLProtocol.response(statusCode: 200), """
            {"seen":false}
            """.data(using: .utf8)!)
        }
        _ = try await sut.updateMessageSeenStatus(id: "msg-1", token: "tok", seen: false)
        XCTAssertEqual(capturedRequest?.value(forHTTPHeaderField: "Content-Type"),
                       "application/merge-patch+json")
    }

    // MARK: - deleteMessage

    func testDeleteMessage_success_doesNotThrow() async throws {
        MockURLProtocol.stub(statusCode: 204)
        try await sut.deleteMessage(id: "msg-1", token: "tok")
    }

    func testDeleteMessage_usesDeleteMethod() async throws {
        var capturedRequest: URLRequest?
        MockURLProtocol.requestHandler = { request in
            capturedRequest = request
            return (MockURLProtocol.response(statusCode: 204), Data())
        }
        try await sut.deleteMessage(id: "msg-1", token: "tok")
        XCTAssertEqual(capturedRequest?.httpMethod, "DELETE")
    }

    func testDeleteMessage_notFound_throwsNotFound() async {
        MockURLProtocol.stub(statusCode: 404)
        do {
            try await sut.deleteMessage(id: "ghost", token: "tok")
            XCTFail("Expected error")
        } catch let error as MailTMError {
            if case .notFound = error { /* pass */ } else {
                XCTFail("Expected .notFound, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - fetchMessageSource

    func testFetchMessageSource_success_returnsMessageAndData() async throws {
        MockURLProtocol.stub(statusCode: 200, data: messageJSON(id: "src-1"))
        let (message, data) = try await sut.fetchMessageSource(id: "src-1", token: "tok")
        XCTAssertEqual(message.id, "src-1")
        XCTAssertFalse(data.isEmpty)
    }

    func testFetchMessageSource_hitsSourcesEndpoint() async throws {
        var capturedURL: URL?
        MockURLProtocol.requestHandler = { request in
            capturedURL = request.url
            return (MockURLProtocol.response(statusCode: 200), self.messageJSON())
        }
        _ = try await sut.fetchMessageSource(id: "src-42", token: "tok")
        XCTAssertTrue(capturedURL?.absoluteString.contains("/sources/src-42") ?? false)
    }

    // MARK: - downloadMessageEML

    func testDownloadMessageEML_success_returnsData() async throws {
        let emlData = "Raw EML content".data(using: .utf8)!
        MockURLProtocol.stub(statusCode: 200, data: emlData)
        let result = try await sut.downloadMessageEML(id: "msg-1", token: "tok")
        XCTAssertEqual(result, emlData)
    }

    func testDownloadMessageEML_hitsDownloadEndpoint() async throws {
        var capturedURL: URL?
        MockURLProtocol.requestHandler = { request in
            capturedURL = request.url
            return (MockURLProtocol.response(statusCode: 200), Data())
        }
        _ = try await sut.downloadMessageEML(id: "eml-99", token: "tok")
        XCTAssertTrue(capturedURL?.absoluteString.contains("/messages/eml-99/download") ?? false)
    }

    func testDownloadMessageEML_notFound_throwsNotFound() async {
        MockURLProtocol.stub(statusCode: 404)
        do {
            _ = try await sut.downloadMessageEML(id: "ghost", token: "tok")
            XCTFail("Expected error")
        } catch let error as MailTMError {
            if case .notFound = error { /* pass */ } else {
                XCTFail("Expected .notFound, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - Error mapping

    func testError_400_throwsInvalidRequest() async {
        MockURLProtocol.stub(statusCode: 400)
        do {
            _ = try await sut.fetchDomains()
            XCTFail("Expected error")
        } catch let error as MailTMError {
            if case .invalidRequest = error { /* pass */ } else {
                XCTFail("Expected .invalidRequest, got \(error)")
            }
        } catch { XCTFail("Unexpected: \(error)") }
    }

    func testError_401_throwsAuthRequired() async {
        MockURLProtocol.stub(statusCode: 401)
        do {
            _ = try await sut.fetchDomains()
            XCTFail("Expected error")
        } catch let error as MailTMError {
            if case .authenticationRequired = error { /* pass */ } else {
                XCTFail("Expected .authenticationRequired, got \(error)")
            }
        } catch { XCTFail("Unexpected: \(error)") }
    }

    func testError_404_throwsNotFound() async {
        MockURLProtocol.stub(statusCode: 404)
        do {
            _ = try await sut.fetchDomains()
            XCTFail("Expected error")
        } catch let error as MailTMError {
            if case .notFound = error { /* pass */ } else {
                XCTFail("Expected .notFound, got \(error)")
            }
        } catch { XCTFail("Unexpected: \(error)") }
    }

    func testError_500_throwsServerError() async {
        MockURLProtocol.stub(statusCode: 500)
        do {
            _ = try await sut.fetchDomains()
            XCTFail("Expected error")
        } catch let error as MailTMError {
            if case .serverError = error { /* pass */ } else {
                XCTFail("Expected .serverError, got \(error)")
            }
        } catch { XCTFail("Unexpected: \(error)") }
    }

    func testError_unknownCode_throwsHttpError() async {
        MockURLProtocol.stub(statusCode: 418)
        do {
            _ = try await sut.fetchDomains()
            XCTFail("Expected error")
        } catch let error as MailTMError {
            if case .httpError(let code, _) = error {
                XCTAssertEqual(code, 418)
            } else {
                XCTFail("Expected .httpError(418), got \(error)")
            }
        } catch { XCTFail("Unexpected: \(error)") }
    }

    // MARK: - 429 retry

    func testFetchDomains_rateLimit_retriesAndSucceeds() async throws {
        var callCount = 0
        MockURLProtocol.requestHandler = { [self] _ in
            callCount += 1
            if callCount == 1 {
                return (MockURLProtocol.response(statusCode: 429), Data())
            }
            return (MockURLProtocol.response(statusCode: 200), self.domainJSON())
        }
        // This test exercises the retry path — it will pause 1.5 s internally.
        // Use a generous timeout.
        let domains = try await sut.fetchDomains()
        XCTAssertEqual(callCount, 2, "Should have retried exactly once")
        XCTAssertEqual(domains.count, 1)
    }

    // MARK: - Network error propagation

    func testNetworkError_wrappedAsMailTMNetworkError() async {
        MockURLProtocol.requestHandler = { _ in throw URLError(.notConnectedToInternet) }
        do {
            _ = try await sut.fetchDomains()
            XCTFail("Expected error")
        } catch let error as MailTMError {
            if case .networkError = error { /* pass */ } else {
                XCTFail("Expected .networkError, got \(error)")
            }
        } catch { XCTFail("Unexpected: \(error)") }
    }

    // MARK: - MailTMError descriptions

    func testErrorDescriptions_areNonEmpty() {
        let errors: [MailTMError] = [
            .invalidURL, .noData, .decodingError(URLError(.badURL)),
            .networkError(URLError(.timedOut)), .httpError(418, "teapot"),
            .authenticationRequired, .rateLimitExceeded, .invalidRequest,
            .notFound, .serverError, .addressAlredyInUse,
        ]
        for error in errors {
            XCTAssertNotNil(error.errorDescription)
            XCTAssertFalse(error.errorDescription!.isEmpty, "Empty description for \(error)")
        }
    }
}
