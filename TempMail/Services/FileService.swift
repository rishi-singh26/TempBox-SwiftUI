//
//  FileService.swift
//  TempMail
//
//  Created by Rishi Singh on 02/05/25.
//

import Foundation

class FileService {
    static func listFilesInApplicationSupportDirectory() -> [URL]? {
        do {
            let supportDir = try FileManager.default.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            
            let fileURLs = try FileManager.default.contentsOfDirectory(
                at: supportDir,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            )
            
            return fileURLs
        } catch {
            print("Error accessing Application Support directory: \(error)")
            return nil
        }
    }
    
    static func getFileContentFromFileImporterResult(_ result: Result<[URL], any Error>) -> (Data?, String?, String) {
        do {
            guard let selectedFile: URL = try result.get().first else { return (nil, nil, "Invalid URL") }
            
            if selectedFile.startAccessingSecurityScopedResource() {
                defer { selectedFile.stopAccessingSecurityScopedResource() }
                
                let data = try Data(contentsOf: selectedFile)
                let content = try String(contentsOf: selectedFile)
//                    let content = String(data: data, encoding: .utf8) // another way of getting the string
                return (data, content, "Success")
            } else {
                return (nil, nil, "Could not access security-scoped resource.")
            }
        } catch {
            return (nil, nil, "Failed to read file: \(error.localizedDescription)")
        }
    }
}
