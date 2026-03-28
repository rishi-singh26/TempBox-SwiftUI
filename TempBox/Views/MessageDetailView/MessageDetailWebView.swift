//
//  MessageDetailWebView.swift
//  TempBox
//
//  Created by Rishi Singh on 28/03/26.
//

import SwiftUI

struct MessageDetailWebView: View {
    @Environment(\.colorScheme) private var appearance
    @EnvironmentObject private var webViewController: WebViewController
    @EnvironmentObject private var appController: AppController
    
    var message: Message
    
    var html: String {
        message.html?.first ?? ""
    }
    
    var body: some View {
        WebView(html: processedHTML, appearance: emailColorScheme, controller: webViewController)
    }
    
    private var processedHTML: String {
        let headerHTML = messageHeaderHTML()
        
        // Dont override styles set with the email
        if html.contains("style") {
            var modifiedHTML = html
            if let bodyOpenRange = modifiedHTML.range(of: "<body[^>]*>", options: .regularExpression) {
                modifiedHTML.insert(contentsOf: headerHTML, at: bodyOpenRange.upperBound)
            }
            return modifiedHTML
        }
        
        let colorScheme = emailColorScheme == .dark ? "dark" : "light"
        let backgroundColor = emailColorScheme == .dark ? "#1a1a1a" : "#ffffff"
        let textColor = emailColorScheme == .dark ? "#ffffff" : "#000000"
        
        
        // Check if HTML already has a complete structure
        if html.lowercased().contains("<html") {
            var modifiedHTML = html
            
            // If it's a complete HTML document, inject our CSS
            let cssInjection = """
                    <style>
                        html {
                            color-scheme: \(colorScheme);
                        }
                        body {
                            background-color: \(backgroundColor) !important;
                            color: \(textColor) !important;
                        }
                        * {
                            color: \(textColor) !important;
                        }
                        a {
                            color: \(appearance == .dark ? "#66b3ff" : "#0066cc") !important;
                        }
                    </style>
                """
            
            if let headRange = html.range(of: "</head>", options: .caseInsensitive) {
                modifiedHTML.insert(contentsOf: cssInjection, at: headRange.lowerBound)
            } else if let bodyRange = html.range(of: "<body", options: .caseInsensitive) {
                modifiedHTML.insert(contentsOf: "<head>\(cssInjection)</head>", at: bodyRange.lowerBound)
            }
            
            if let bodyOpenRange = modifiedHTML.range(of: "<body[^>]*>", options: .regularExpression) {
                modifiedHTML.insert(contentsOf: headerHTML, at: bodyOpenRange.upperBound)
            }
            
            return modifiedHTML;
        }
        
        // If it's HTML fragment or no head/body tags, wrap it completely
        return """
                <!DOCTYPE html>
                <html>
                <head>
                    <meta charset="utf-8">
                    <meta name="viewport" content="width=device-width, initial-scale=1.0">
                    <style>
                        html {
                            color-scheme: \(colorScheme);
                        }
                        body {
                            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                            background-color: \(backgroundColor);
                            color: \(textColor);
                            margin: 0;
                            padding: 16px;
                        }
                        a {
                            color: \(appearance == .dark ? "#66b3ff" : "#0066cc");
                        }
                    </style>
                </head>
                <body>
                    \(headerHTML)
                    \(html)
                </body>
                </html>
            """
    }
    
    private func messageHeaderHTML() -> String {
        
        let header: String
        let subHeader: String
        
        if let name = message.fromName, !name.isEmpty {
            header = name
            subHeader = message.fromAddress
        } else {
            header = message.fromAddress
            subHeader = ""
        }
        
        let backgroundColor = emailColorScheme == .dark ? "#1a1a1a" : "#ffffff"
        let textColor = emailColorScheme == .dark ? "#ffffff" : "#000000"
        
        let subHeaderHTML: String = {
            if subHeader.isEmpty {
                return ""
            } else {
                return """
                <a href="mailto:\(subHeader)" style="text-decoration:none; color: #e82845">
                    \(subHeader)
                </a>
                """
            }
        }()
        
        return """
        <div style="
            display: flex;
            align-items: center;
            padding: 5px 8px;
            background: \(backgroundColor);
            font-family: -apple-system, BlinkMacSystemFont, sans-serif;
        ">
            <div style="
                width: 45px;
                height: 45px;
                background: #007AFF;
                color: white;
                border-radius: 50%;
                display: flex;
                align-items: center;
                justify-content: center;
                margin-right: 8px;
                font-weight: bold;
            ">
                \(header.getInitials())
            </div>
            
            <div style="display: flex; flex-direction: column;">
                <span style="font-size: 16px; font-weight: 600; color: \(textColor);">
                    \(header)
                </span>
                <span style="font-size: 14px;">
                    \(subHeaderHTML)
                </span>
            </div>
            
            <div style="margin-left: auto; font-size: 12px; color: gray;">
                \(message.createdAtFormatted)
            </div>
        </div>
        <h2 style="
            background: \(backgroundColor);
            color: \(textColor);
            margin: 0 !important;
            padding:5px;
            font-family: -apple-system, BlinkMacSystemFont, sans-serif;">
            \(message.subject)
        </h2>
        """
    }
    
    private var emailColorScheme: ColorScheme {
        switch appController.webViewColorScheme {
        case .dark:
            return .dark
        case .light:
            return .light
        case .system:
            return appearance
        }
    }
}

//#Preview {
//    MessageDetailWebView()
//}
