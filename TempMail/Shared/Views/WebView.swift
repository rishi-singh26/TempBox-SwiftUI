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

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeView(context: Context) -> PlatformWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
#if os(iOS)
        webView.isOpaque = false
        webView.backgroundColor = .clear
#endif
        webView.navigationDelegate = context.coordinator
        context.coordinator.webView = webView
        webView.loadHTMLString(html, baseURL: nil)
        return webView
    }

    func updateView(_ webView: PlatformWebView, context: Context) {
        webView.loadHTMLString(html, baseURL: nil)
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
}

#Preview {
    WebView(html: """
        <html><body>
        <h1>Email Preview</h1>
        <p>Click <a href='https://www.apple.com'>here</a> to visit Apple.</p>
        </body></html>
    """)
}
