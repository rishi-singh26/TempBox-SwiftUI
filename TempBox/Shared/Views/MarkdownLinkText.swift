//
//  MarkdownLinkText.swift
//  TempBox
//
//  Created by Rishi Singh on 02/05/25.
//

import SwiftUI

struct MarkdownLinkText: View {
    let markdownText: String
    @State private var showAlert = false
    @State private var linkToOpen: URL?
    
    @Environment(\.openURL) var openURL

    var body: some View {
        Text(attributedString)
            .onTapGesture {
                if let url = linkURL {
                    linkToOpen = url
                    showAlert = true
                }
            }
            .alert("Open Link?", isPresented: $showAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Open", role: .destructive) {
                    if let url = linkToOpen {
                        openURL(url)
                    }
                }
            } message: {
                Text(linkToOpen?.absoluteString ?? "")
            }
    }

    private var attributedString: AttributedString {
        if let (before, linkText, after) = parsedTextComponents {
            var result = AttributedString()
            result += AttributedString(before)

            var linkPart = AttributedString(linkText.text)
            linkPart.foregroundColor = .accentColor
//            linkPart.underlineStyle = .single

            result += linkPart
            result += AttributedString(after)
            return result
        } else {
            return AttributedString(markdownText) // fallback: plain text
        }
    }

    private var linkURL: URL? {
        parsedTextComponents?.linkText.url
    }

    private var parsedTextComponents: (before: String, linkText: (text: String, url: URL), after: String)? {
        let pattern = #"(.*?)?\[(.*?)\]\((.*?)\)(.*)?"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let nsrange = NSRange(markdownText.startIndex..<markdownText.endIndex, in: markdownText)

        guard let match = regex.firstMatch(in: markdownText, range: nsrange),
              let linkTextRange = Range(match.range(at: 2), in: markdownText),
              let urlRange = Range(match.range(at: 3), in: markdownText),
              let url = URL(string: String(markdownText[urlRange]))
        else {
            return nil
        }

        let before = (Range(match.range(at: 1), in: markdownText).map { String(markdownText[$0]) }) ?? ""
        let after = (Range(match.range(at: 4), in: markdownText).map { String(markdownText[$0]) }) ?? ""
        let linkText = String(markdownText[linkTextRange])

        return (before, (linkText, url), after)
    }
}

#Preview {
    MarkdownLinkText(markdownText: "Powered by [mail.tm](https://www.mail.tm)")
    MarkdownLinkText(markdownText: "[\("rishi@email.com")](mailto:\("rishi@email.com"))")
    MarkdownLinkText(markdownText: "Powered by [mail.tm](https://www.mail.tm)")
    MarkdownLinkText(markdownText: "Click [here](https://example.com) to continue...")
    MarkdownLinkText(markdownText: "[mail.tm](https://www.mail.tm)")
}
