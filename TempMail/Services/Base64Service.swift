//
//  Base64Service.swift
//  TempMail
//
//  Created by Rishi Singh on 02/05/25.
//

import Foundation

class Base64Service {
    /// Validate id the input is a valid Base64
    static func isValidBase64(_ string: String) -> Bool {
        // Base64 strings must only contain A–Z, a–z, 0–9, +, / and = as padding
        let pattern = "^[A-Za-z0-9+/]*={0,2}$"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: string.utf16.count)
        
        guard let match = regex?.firstMatch(in: string, options: [], range: range) else {
            return false
        }
        
        // Also ensure the length is a multiple of 4
        return match.range.length == string.utf16.count && string.count % 4 == 0
    }
    
    static func validateAndDecodeBase64(_ base64: String) -> String? {
        guard isValidBase64(base64) else {
            return nil
        }
        guard let data = Data(base64Encoded: base64),
              let decoded = String(data: data, encoding: .utf8) else {
            return nil
        }
        return decoded
    }
    
    /// Get String? from base 64
    static func decodeBase64(_ base64: String) -> String? {
        guard let data = Data(base64Encoded: base64),
              let decoded = String(data: data, encoding: .utf8) else {
            return nil
        }
        return decoded
    }
    
    /// Get Base64 from String
    static func encodeBase64(_ string: String) -> String {
        let data = Data(string.utf8)
        return data.base64EncodedString()
    }
}
