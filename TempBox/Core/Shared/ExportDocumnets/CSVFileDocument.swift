//
//  CSVFileDocument.swift
//  TempBox
//
//  Created by Rishi Singh on 11/06/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct CSVFileDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.commaSeparatedText] }
    static var writableContentTypes: [UTType] { [.commaSeparatedText] }
    static let contentType: UTType = .commaSeparatedText

    var csvText: String

    init(csvText: String) {
        self.csvText = csvText
    }

    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents,
           let text = String(data: data, encoding: .utf8) {
            csvText = text
        } else {
            throw CocoaError(.fileReadCorruptFile)
        }
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = csvText.data(using: .utf8)!
        return FileWrapper(regularFileWithContents: data)
    }
}
