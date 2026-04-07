//
//  FileDocument.swift
//  TempBox
//
//  Created by Rishi Singh on 14/06/25.
//

import SwiftUI
import UniformTypeIdentifiers

// Custom FileDocument conforming to your file type
struct MyFileDocument: FileDocument {
    static var readableContentTypes: [UTType] {
        [.data] // Adjust based on your file type
    }
    
    var data: Data
    
    init(data: Data = Data()) {
        self.data = data
    }
    
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.data = data
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        return FileWrapper(regularFileWithContents: data)
    }
}
