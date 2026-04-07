//
//  MockURLProtocol.swift
//  TempBoxTests
//
//  Intercepts URLSession requests and returns canned responses for unit testing.
//

import Foundation

final class MockURLProtocol: URLProtocol {

    /// Set this before each test. Receives the outgoing request; returns (response, data) or throws.
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.unknown))
            return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

// MARK: - Helpers used across test files

extension MockURLProtocol {
    /// Returns a URLSession configured to use MockURLProtocol.
    static func makeSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: config)
    }

    /// Creates an HTTPURLResponse with the given status code.
    static func response(statusCode: Int, url: URL = URL(string: "https://api.mail.tm")!) -> HTTPURLResponse {
        HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: "HTTP/1.1", headerFields: nil)!
    }

    /// Encodes a value to JSON Data; crashes on failure (test helper only).
    static func encode<T: Encodable>(_ value: T) -> Data {
        try! JSONEncoder().encode(value)
    }

    /// Registers a handler that always returns the given status + body.
    static func stub(statusCode: Int, data: Data = Data()) {
        requestHandler = { _ in
            (response(statusCode: statusCode), data)
        }
    }
}
