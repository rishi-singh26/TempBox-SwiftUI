//
//  StringExtensions.swift
//  TempBox
//
//  Created by Rishi Singh on 23/09/23.
//

import SwiftUI

extension String {
    /// Generates a unique, fun username suitable for an email address.
    /// - Returns: A unique username string.
    static func generateUsername() -> String {
        var username: String
        
        let adjective = KAdjectives.randomElement()!
        let noun = KNouns.randomElement()!
        let number = Int.random(in: 0...9999)
        
        // Compose username like "FunkyTiger47213"
        username = "\(adjective)\(noun)\(number)"
        
        return username.lowercased()
    }

    /// Generates a random password containing uppercase, lowercase, digits, and special characters.
    /// - Parameter length: The desired length of the password. Default is 12 characters.
    /// - Parameter useUpperCase: Include upper case characters in the result. Default `false`.
    /// - Parameter useNumbers: Include numbers in the result. Default `false`.
    /// - Parameter useSpecialCharacters: Include special characters in the result. Default `false`.
    /// - Returns: A randomly generated password string.
    static func generatePassword(of length: Int, useUpperCase: Bool = false, useNumbers: Bool = false, useSpecialCharacters: Bool = false) -> String {
        var characterPool = "abcdefghijklmnopqrstuvwxyz" // Always include lowercase letters
        
        if useUpperCase {
            characterPool += "ABCDEFGHIJKLMNOPQRSTUVWXYZ" // Add uppercase letters if specified
        }
        
        if useNumbers {
            characterPool += "0123456789" // Add digits if specified
        }
        
        if useSpecialCharacters {
            characterPool += "!@#$%^&*()_-+=<>?" // Add special characters if specified
        }
        
        // Ensure the pool is not empty
        if characterPool.isEmpty {
            fatalError("You must select at least one character type (uppercase, numbers, or special characters).")
        }

        var password = ""
        
        // Ensure the password has at least one character from each selected category
        if useUpperCase {
            password += String("ABCDEFGHIJKLMNOPQRSTUVWXYZ".randomElement()!)
        }
        
        if useNumbers {
            password += String("0123456789".randomElement()!)
        }
        
        if useSpecialCharacters {
            password += String("!@#$%^&*()_-+=<>?".randomElement()!)
        }
        
        // Add random characters from the selected pool until the password reaches the desired length
        for _ in password.count..<length {
            password += String(characterPool.randomElement()!)
        }
        
        // Shuffle the password to make it more unpredictable
        return String(password.shuffled())
    }
    
    func getInitials() -> String {
        let formatter = PersonNameComponentsFormatter()
        if let components = formatter.personNameComponents(from: self) {
             formatter.style = .abbreviated
             return formatter.string(from: components)
        }
        return self
    }
    
    /// This will return the user name from an email
    /// If the string is not an email, will return the strinng without any changes
    func extractUsername() -> String {
        if !self.isValidEmail() {
            return self
        }
        
        let components = self.components(separatedBy: "@")

        if components.count == 2 {
            let username = components[0]
            if !username.isEmpty{
               return username
            }
            else{
                return self
            }
        } else {
            return self
        }
    }
    
    func isValidEmail() -> Bool {
        guard self.contains("@") else { return false }
        
        let emailRegex = "^[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,64}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES[c] %@", emailRegex)
        return emailPredicate.evaluate(with: self)
    }
    
    func copyToClipboard() {
#if os(iOS)
        UIPasteboard.general.string = self
#elseif os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(self, forType: .string)
#else
        // Handle other platforms if needed, or provide a default
        print("Clipboard operations not supported on this platform.")
#endif
    }
    
    func isValidISO8601Date() -> Bool {
        // let regex = #"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z$"#
        let regex = "^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}(\\.\\d+)?(Z|[+-]\\d{2}:\\d{2})$"
        return self.range(of: regex, options: .regularExpression) != nil
    }
    
    func validateAndToDate() -> Date? {
        guard isValidISO8601Date() else {
            return nil
        }
        
        return toDate()
    }
    
    func toDate() -> Date? {
        let formatter = ISO8601DateFormatter()
        
        // Try parsing with fractional seconds first
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: self) {
            return date
        }
        
        // Fallback to parsing without fractional seconds
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: self)
    }

}
