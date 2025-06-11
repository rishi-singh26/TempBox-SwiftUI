//
//  JSONFileDocument.swift
//  TempMail
//
//  Created by Rishi Singh on 11/06/25.
//

import SwiftUI
import UniformTypeIdentifiers

enum JSONFileDocumentError: Error {
    case stringToDataConversionFailed
    case encodingFailed(underlying: Error)
    
    var errorDescription: String? {
        switch self {
        case .stringToDataConversionFailed:
            return "Failed to convert string to UTF-8 encoded data."
        case .encodingFailed(let underlying):
            return "Failed to encode object to JSON. Reason: \(underlying.localizedDescription)"
        }
    }
}

protocol JSONEncodable: Encodable {
    func toJSON(prettyPrinted: Bool) throws -> String
    func toJSON(prettyPrinted: Bool) throws -> Data
}

struct JSONFileDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    static var writableContentTypes: [UTType] { [.json] }
    static let contentType: UTType = .json
    static let dummyDoc = JSONFileDocument(data: "{ \"data\": \"Hello World!\"}".data(using: .utf8)!)

    let jsonData: Data
    
    
    // MARK: - Initializers
    /// Create JSON document with JSON `String`
    init(content: String) throws {
        guard let data = content.data(using: .utf8) else {
            throw JSONFileDocumentError.stringToDataConversionFailed
        }
        self.jsonData = data
    }
    
    /// Create JSON document with `Data`
    init(data: Data) {
        self.jsonData = data
    }
    
    /// Create JSON document with any Object T that conforms to `JSONEncodable`
    init<T: JSONEncodable>(object: T) throws {
        do {
            self.jsonData = try object.toJSON(prettyPrinted: true)
        } catch {
            throw JSONFileDocumentError.encodingFailed(underlying: error)
        }
    }

    /// Create JSON document with `ReadConfiguration`
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        jsonData = data
    }

    
    // MARK: - Methods
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: jsonData)
    }
}
