//
//  QuicklookPreview.swift
//  TempBox
//
//  Created by Rishi Singh on 11/06/25.
//

import SwiftUI

#if os(iOS) || os(iPadOS)
import UIKit
import QuickLook

struct QuicklookPreview: UIViewControllerRepresentable {
    let urls: [URL]
    
    func makeUIViewController(context: Context) -> QLPreviewController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(urls: urls)
    }
    
    class Coordinator: NSObject, QLPreviewControllerDataSource {
        let urls: [URL]
        
        init(urls: [URL]) {
            self.urls = urls
        }
        
        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            return urls.count
        }
        
        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            return urls[index] as QLPreviewItem
        }
    }
}
#endif

#if os(macOS)
import AppKit
import Quartz

struct QuicklookPreview: NSViewRepresentable {
    let urls: [URL]
    var currentIndex: Int = 0

    func makeNSView(context: Context) -> QLPreviewView {
        let frame = NSRect(x: 0, y: 0, width: 400, height: 300)
        guard let previewView = QLPreviewView(frame: frame, style: .normal) else {
            // return an empty NSView() if creation fails
            return QLPreviewView()
        }
        previewView.autoresizingMask = [.width, .height]

        if urls.indices.contains(currentIndex) {
            previewView.previewItem = urls[currentIndex] as QLPreviewItem
        }

        return previewView
    }

    func updateNSView(_ nsView: QLPreviewView, context: Context) {
        if urls.indices.contains(currentIndex) {
            nsView.previewItem = urls[currentIndex] as QLPreviewItem
        }
    }
}
#endif
