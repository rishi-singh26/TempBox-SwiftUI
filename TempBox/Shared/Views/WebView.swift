//
//  WebView.swift
//  TempBox
//
//  Created by Rishi Singh on 01/05/25.
//

import SwiftUI
import WebKit

#if os(iOS)
typealias PlatformViewRepresentable = UIViewRepresentable
typealias PlatformWebView = WKWebView
#elseif os(macOS)
typealias PlatformViewRepresentable = NSViewRepresentable
typealias PlatformWebView = WKWebView
#endif

struct WebView: PlatformViewRepresentable {
    let html: String
    let appearance: ColorScheme

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeView(context: Context) -> PlatformWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        
        // Apply appearance settings
        applyAppearance(to: webView)
        
#if os(iOS)
        webView.isOpaque = false
        webView.backgroundColor = .clear
#endif
        webView.navigationDelegate = context.coordinator
        context.coordinator.webView = webView
        webView.loadHTMLString(processedHTML, baseURL: nil)
        return webView
    }

    func updateView(_ webView: PlatformWebView, context: Context) {
        // Apply appearance settings on update
        applyAppearance(to: webView)
        webView.loadHTMLString(processedHTML, baseURL: nil)
    }
    
    private func applyAppearance(to webView: WKWebView) {
        #if os(iOS)
        switch appearance {
        case .light:
            webView.overrideUserInterfaceStyle = .light
        case .dark:
            webView.overrideUserInterfaceStyle = .dark
        @unknown default:
            webView.overrideUserInterfaceStyle = UITraitCollection.current.userInterfaceStyle
        }
        #elseif os(macOS)
        switch appearance {
        case .light:
            webView.appearance = NSAppearance(named: .aqua)
        case .dark:
            webView.appearance = NSAppearance(named: .darkAqua)
        @unknown default:
            webView.appearance = NSApp.effectiveAppearance
        }
        #endif
    }

    #if os(iOS)
    func makeUIView(context: Context) -> PlatformWebView {
        makeView(context: context)
    }

    func updateUIView(_ uiView: PlatformWebView, context: Context) {
        updateView(uiView, context: context)
    }
    #elseif os(macOS)
    func makeNSView(context: Context) -> PlatformWebView {
        makeView(context: context)
    }

    func updateNSView(_ nsView: PlatformWebView, context: Context) {
        updateView(nsView, context: context)
    }
    #endif

    class Coordinator: NSObject, WKNavigationDelegate {
        weak var webView: WKWebView?

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {

            guard let url = navigationAction.request.url else {
                decisionHandler(.allow)
                return
            }

            // Prevent all external navigations (including redirects)
            if navigationAction.navigationType == .linkActivated {
                // Intercept and confirm before opening externally
                decisionHandler(.cancel)
                confirmAndOpenExternally(url: url)
            } else if navigationAction.targetFrame == nil {
                // Handles _blank targets, cancel and open externally
                decisionHandler(.cancel)
                confirmAndOpenExternally(url: url)
            } else {
                // Allow initial email content only
                decisionHandler(.allow)
            }
        }

        private func confirmAndOpenExternally(url: URL) {
            #if os(iOS)
            guard let scene = UIApplication.shared.connectedScenes
                    .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
                  let rootVC = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController else { return }

            let alert = UIAlertController(title: "Open Link?",
                                          message: "Do you want to open this link in your browser?\n\n\(url.absoluteString)",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            alert.addAction(UIAlertAction(title: "Copy", style: .default) { _ in
                url.absoluteString.copyToClipboard()
            })
            alert.addAction(UIAlertAction(title: "Open", style: .default) { _ in
                UIApplication.shared.open(url)
            })

            DispatchQueue.main.async {
                rootVC.present(alert, animated: true)
            }

            #elseif os(macOS)
            let alert = NSAlert()
            alert.messageText = "Open Link?"
            alert.informativeText = "Do you want to open this link in your browser?\n\n\(url.absoluteString)"
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Open")
            alert.addButton(withTitle: "Copy")
            alert.addButton(withTitle: "Cancel")
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                NSWorkspace.shared.open(url)
            }
            if response == .alertSecondButtonReturn {
                url.absoluteString.copyToClipboard()
            }
            #endif
        }
    }
    
    private var processedHTML: String {
        if html.contains("style") { // Dont override styles set with the email
            return html
        }
        let colorScheme = appearance == .dark ? "dark" : "light"
        let backgroundColor = appearance == .dark ? "#1a1a1a" : "#ffffff"
        let textColor = appearance == .dark ? "#ffffff" : "#000000"
        
        // Check if HTML already has a complete structure
        if html.lowercased().contains("<html") {
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
                var modifiedHTML = html
                modifiedHTML.insert(contentsOf: cssInjection, at: headRange.lowerBound)
                return modifiedHTML
            } else if let bodyRange = html.range(of: "<body", options: .caseInsensitive) {
                var modifiedHTML = html
                modifiedHTML.insert(contentsOf: "<head>\(cssInjection)</head>", at: bodyRange.lowerBound)
                return modifiedHTML
            }
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
                    \(html)
                </body>
                </html>
            """
    }
}

#Preview {
    VStack {
        WebView(html: """
            <html><body>
            <h1>Email Preview (Light)</h1>
            <p>Click <a href='https://www.apple.com'>here</a> to visit Apple.</p>
            </body></html>
        """, appearance: .light)
        
        WebView(html: """
            <html><body style="background-color: #1a1a1a; color: white;">
            <h1>Email Preview (Dark)</h1>
            <p>Click <a href='https://www.apple.com'>here</a> to visit Apple.</p>
            </body></html>
        """, appearance: .dark)
    }
}
