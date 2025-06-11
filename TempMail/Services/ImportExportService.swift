//
//  ImportExportService.swift
//  TempMail
//
//  Created by Rishi Singh on 02/05/25.
//

import Foundation

class ImportExportService {
    static func decodeDataForImport(from importContent: String) -> (ExportVersionOne?, ExportVersionTwo?, String) {
        guard let json = Base64Service.validateAndDecodeBase64(importContent),
              let jsonData = json.data(using: .utf8) else {
            return (nil, nil, "Decoding from base64 failed")
        }
        
        do {
            // Decode version only
            let versionContainer = try JSONDecoder().decode(VersionContainer.self, from: jsonData)
            
            switch versionContainer.version {
            case "1.0.0":
                let (decoded, message) = ImportExportService.decodeVersionOneData(from: jsonData)
                return (decoded, nil, message)
                
            case "2.0.0":
                let (decoded, message) = ImportExportService.decodeVersionTwoData(from: jsonData)
                return (nil, decoded, message)
                
            default:
                return (nil, nil, "Unsupported version: \(versionContainer.version)")
            }
        } catch {
            return (nil, nil, "Failed to decode version info: \(error)")
        }
    }
    
    static func decodeVersionOneData(from data: Data) -> (ExportVersionOne?, String) {
        do {
            let decodedData = try JSONDecoder().decode(ExportVersionOne.self, from: data)
            return (decodedData, "Success")
        } catch {
            return (nil, "Decoding failed: \(error)")
        }
    }
    
    static func decodeVersionTwoData(from data: Data) -> (ExportVersionTwo?, String) {
        do {
            let decodedData = try JSONDecoder().decode(ExportVersionTwo.self, from: data)
            return (decodedData, "Success")
        } catch {
            return (nil, "Decoding failed: \(error)")
        }
    }
}
