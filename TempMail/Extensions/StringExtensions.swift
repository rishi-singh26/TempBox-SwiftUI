//
//  StringExtensions.swift
//  TempBox
//
//  Created by Rishi Singh on 23/09/23.
//

import SwiftUI

extension String {
    static func generateRandomString(of length: Int, useUpperCase: Bool = false, useNumbers: Bool = false, useSpecialCharacters: Bool = false) -> String {
        var letters = "abcdefghijklmnopqrstuvwxyz"
        if useUpperCase {
            letters += "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        }
        if useNumbers {
            letters += "0123456789"
        }
        if useSpecialCharacters {
            letters += "@$%&*#()"
        }
        return String((0..<length).map{ _ in letters.randomElement()! })
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
}
