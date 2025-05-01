//
//  ShareService.swift
//  TempBox
//
//  Created by Rishi Singh on 02/10/23.
//

//import SwiftUI
//import WebKit
//import PDFKit
//
//class ShareService {
//    func convertHTMLToPDF(html: String) -> PDFDocument? {
//        let webView = WKWebView()
//        webView.loadHTMLString(html, baseURL: nil)
//        
//        var pdfDoc: PDFDocument?
//        
////        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//            let config = WKPDFConfiguration()
//            config.rect = .init(origin: .zero, size: .init(width: 595.28, height: 841.89))
//            webView.createPDF(configuration: config) { result in
//                switch result {
//                case .success(let data):
//                    pdfDoc = PDFDocument(data: data)
//                case .failure(let error):
//                    print("Error creating PDF \(error)")
//                }
//            }
////        }
//        
//        return pdfDoc
//    }
//    
//    func createPDF(html: String) -> Data? {
//        let format = UIGraphicsPDFRendererFormat()
//        let bounds = CGRect(x: 0, y: 0, width: 500, height: 600)
//        let renderer = UIGraphicsPDFRenderer(bounds: bounds, format: format)
//
//        let data = renderer.pdfData { context in
//            context.beginPage()
//            let attributes = [
//                NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12),
//                NSAttributedString.Key.foregroundColor: UIColor.black
//            ]
//            let string = NSAttributedString(string: html, attributes: attributes)
//            string.draw(in: bounds)
//        }
//        
//        return data
//    }
//
//}
