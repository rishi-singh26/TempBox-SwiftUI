//
//  WebView.swift
//  TempBox
//
//  Created by Rishi Singh on 01/05/25.
//

import SwiftUI
import WebKit
import PDFKit

#if os(iOS)
typealias PlatformViewRepresentable = UIViewRepresentable
typealias PlatformWebView = WKWebView
#elseif os(macOS)
typealias PlatformViewRepresentable = NSViewRepresentable
typealias PlatformWebView = WKWebView
#endif

// Custom error types for better error handling
enum PDFError: LocalizedError {
    case webViewNotAvailable
    case generationFailed(String)
    case contentNotReady
    
    var errorDescription: String? {
        switch self {
        case .webViewNotAvailable:
            return "WebView is not available for PDF generation"
        case .generationFailed(let reason):
            return "PDF generation failed: \(reason)"
        case .contentNotReady:
            return "WebView content is not ready for PDF generation"
        }
    }
}

struct WebView: PlatformViewRepresentable {
    let html: String
    let appearance: ColorScheme
    @ObservedObject var controller: WebViewController

    func makeCoordinator() -> Coordinator {
        let coordinator = Coordinator()
        controller.coordinator = coordinator
        return coordinator
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
        
        func saveAsPDF() async throws -> Data? {
            guard let webView = webView else {
                throw PDFError.webViewNotAvailable
            }
            
            // Wait for content to finish loading
            return await withCheckedContinuation { continuation in
                webView.evaluateJavaScript("document.readyState") { result, error in
                    if let state = result as? String, state == "complete" {
                        self.generatePDFWithPDFKit(webView: webView) { data in
                            continuation.resume(returning: data)
                        }
                    } else {
                        // Wait a bit more for content to load
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self.generatePDFWithPDFKit(webView: webView) { data in
                                continuation.resume(returning: data)
                            }
                        }
                    }
                }
            }
        }
        
        private func generatePDFWithPDFKit(webView: WKWebView, completion: @escaping (Data?) -> Void) {
#if os(iOS)
            generatePDFiOS(webView: webView, completion: completion)
#elseif os(macOS)
            generatePDFmacOS(webView: webView, completion: completion)
#endif
        }
        
#if os(iOS)
        private func generatePDFiOS(webView: WKWebView, completion: @escaping (Data?) -> Void) {
            // Use UIPrintPageRenderer with PDFKit
            let renderer = UIPrintPageRenderer()
            let formatter = webView.viewPrintFormatter()
            
            renderer.addPrintFormatter(formatter, startingAtPageAt: 0)
            
            // Set up page size (US Letter: 8.5" x 11")
            let pageSize = CGSize(width: 612, height: 792) // 72 points per inch
            let pageMargins = UIEdgeInsets(top: 36, left: 36, bottom: 36, right: 36) // 0.5" margins
            
            let paperRect = CGRect(origin: .zero, size: pageSize)
            let printableRect = CGRect(
                x: pageMargins.left,
                y: pageMargins.top,
                width: pageSize.width - pageMargins.left - pageMargins.right,
                height: pageSize.height - pageMargins.top - pageMargins.bottom
            )
            
            renderer.setValue(paperRect, forKey: "paperRect")
            renderer.setValue(printableRect, forKey: "printableRect")
            
            // Create PDF data using PDFKit
            let pdfData = NSMutableData()
            UIGraphicsBeginPDFContextToData(pdfData, paperRect, nil)
            
            let numberOfPages = renderer.numberOfPages
            for pageIndex in 0..<numberOfPages {
                UIGraphicsBeginPDFPage()
                let bounds = UIGraphicsGetPDFContextBounds()
                renderer.drawPage(at: pageIndex, in: bounds)
            }
            
            UIGraphicsEndPDFContext()
            
            // Convert to PDFDocument for better handling (optional)
            if let pdfDocument = PDFDocument(data: pdfData as Data) {
                completion(pdfDocument.dataRepresentation())
            } else {
                completion(pdfData as Data)
            }
        }
#endif
        
#if os(macOS)
        private func generatePDFmacOS(webView: WKWebView, completion: @escaping (Data?) -> Void) {
            // Create print info
            let printInfo = NSPrintInfo.shared.copy() as! NSPrintInfo
            printInfo.horizontalPagination = .fit
            printInfo.verticalPagination = .automatic
            printInfo.orientation = .portrait
            printInfo.leftMargin = 36.0  // 0.5 inch
            printInfo.rightMargin = 36.0
            printInfo.topMargin = 36.0
            printInfo.bottomMargin = 36.0
            
            // Use WKWebView's createPDF method (available on macOS 11+)
            if #available(macOS 11.0, *) {
                // Don't set rect to allow full content capture across multiple pages
                let config = WKPDFConfiguration()
                
                webView.createPDF(configuration: config) { result in
                    switch result {
                    case .success(let data):
                        completion(data)
                    case .failure(_):
                        completion(nil)
                    }
                }
            } else {
                // Fallback for older macOS versions using NSPrintOperation
                generatePDFLegacyMacOS(webView: webView, printInfo: printInfo, completion: completion)
            }
        }
        
        private func generatePDFLegacyMacOS(webView: WKWebView, printInfo: NSPrintInfo, completion: @escaping (Data?) -> Void) {
            // First, get the full content height of the web page
            webView.evaluateJavaScript("Math.max(document.body.scrollHeight, document.body.offsetHeight, document.documentElement.clientHeight, document.documentElement.scrollHeight, document.documentElement.offsetHeight)") { result, error in
                
                guard let contentHeight = result as? CGFloat else {
                    completion(nil)
                    return
                }
                
                let pageWidth = printInfo.paperSize.width
                let pageHeight = printInfo.paperSize.height
                let printableWidth = pageWidth - printInfo.leftMargin - printInfo.rightMargin
                let printableHeight = pageHeight - printInfo.topMargin - printInfo.bottomMargin
                
                // Calculate number of pages needed
                let numberOfPages = Int(ceil(contentHeight / printableHeight))
                
                // Create PDF data
                let pdfData = NSMutableData()
                let dataConsumer = CGDataConsumer(data: pdfData)!
                var mediaBox = CGRect(origin: .zero, size: printInfo.paperSize)
                
                guard let pdfContext = CGContext(consumer: dataConsumer, mediaBox: &mediaBox, nil) else {
                    completion(nil)
                    return
                }
                
                // Create each page
                for pageIndex in 0..<numberOfPages {
                    pdfContext.beginPDFPage(nil)
                    
                    let nsGraphicsContext = NSGraphicsContext(cgContext: pdfContext, flipped: false)
                    NSGraphicsContext.current = nsGraphicsContext
                    
                    // Calculate the scroll offset for this page
                    let scrollOffset = CGFloat(pageIndex) * printableHeight
                    
                    // Scroll the webview to the correct position
                    let scrollScript = "window.scrollTo(0, \(scrollOffset));"
                    
                    let semaphore = DispatchSemaphore(value: 0)
                    
                    DispatchQueue.main.async {
                        webView.evaluateJavaScript(scrollScript) { _, _ in
                            // Give the webview time to render after scrolling
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                // Apply transformation to position content correctly
                                pdfContext.saveGState()
                                
                                // Translate to apply margins
                                pdfContext.translateBy(x: printInfo.leftMargin, y: printInfo.bottomMargin)
                                
                                // Translate to show the correct portion of content
                                pdfContext.translateBy(x: 0, y: -scrollOffset)
                                
                                // Clip to printable area
                                pdfContext.clip(to: CGRect(x: 0, y: scrollOffset, width: printableWidth, height: printableHeight))
                                
                                // Render the web view content
                                if let layer = webView.layer {
                                    layer.render(in: pdfContext)
                                }
                                
                                pdfContext.restoreGState()
                                pdfContext.endPDFPage()
                                
                                semaphore.signal()
                            }
                        }
                    }
                    
                    semaphore.wait()
                }
                
                pdfContext.closePDF()
                NSGraphicsContext.current = nil
                
                // Reset scroll position
                DispatchQueue.main.async {
                    webView.evaluateJavaScript("window.scrollTo(0, 0);") { _, _ in
                        completion(pdfData as Data)
                    }
                }
            }
        }
#endif
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

final class WebViewController: ObservableObject {
    fileprivate var coordinator: WebView.Coordinator?

    func saveAsPDF() async throws -> Data? {
        try await coordinator?.saveAsPDF()
    }
}

#Preview {
    VStack {
        WebView(html: """
            <html><body>
            <h1>Email Preview (Light)</h1>
            <p>Click <a href='https://www.apple.com'>here</a> to visit Apple.</p>
            </body></html>
        """, appearance: .light, controller: WebViewController())

        WebView(html: """
            <html><body style="background-color: #1a1a1a; color: white;">
            <h1>Email Preview (Dark)</h1>
            <p>Click <a href='https://www.apple.com'>here</a> to visit Apple.</p>
            </body></html>
        """, appearance: .dark, controller: WebViewController())
    }
}
