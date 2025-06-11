//
//  Base64Service.swift
//  TempBox
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
    
    /// Validate input to check if its Base64, If its not valid Base64 then return the input String
    /// ---
    /// If its Base64 then and decoding fails return nil
    /// ---
    /// if its Base64 then decode and return decodedString
    /// ---
    static func validateAndDecodeBase64(_ base64: String) -> String? {
        guard isBase64EncodedString(base64) else {
            return base64 // return the input string as is
        }
        guard let data = Data(base64Encoded: base64),
              let decoded = String(data: data, encoding: .utf8) else {
            return nil // return empty String if decoding the Base64 fails
        }
        return decoded // return the decoded base64
    }
    
    /// Validate if the input is a valid Base64 String
    static func isBase64EncodedString(_ input: String) -> Bool {
        // Step 1: Attempt to decode from Base64
        guard let decodedData = Data(base64Encoded: input) else {
            return false
        }

        // Step 2: Try to convert the decoded data into a String
        guard let decodedString = String(data: decodedData, encoding: .utf8) else {
            return false
        }

        // Step 3: Re-encode the decoded string and compare
        let reEncoded = Data(decodedString.utf8).base64EncodedString()

        // Step 4: Compare ignoring padding or line wrapping differences
        return reEncoded == input
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
    static func encodeBase64(_ string: String) throws -> String {
        if let base64 = string.data(using: .utf8)?.base64EncodedString() {
            return base64
        } else {
            throw JSONFileDocumentError.stringToDataConversionFailed
        }
    }
}
