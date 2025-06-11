//
//  QuicklookPreview.swift
//  TempBox
//
//  Created by Rishi Singh on 11/06/25.
//

import Foundation

// Usage
//QuickLookPreview.preview(url: exportedFileURL)

enum QuickLookPreview {
    static func preview(url: URL) {
        #if os(iOS) || os(iPadOS)
        QuickLookPreview_iOS.preview(url: url)
        #elseif os(macOS)
        QuickLookPreview_macOS.preview(url: url)
        #endif
    }
}

#if os(iOS) || os(iPadOS)
import UIKit
import QuickLook

final class QuickLookPreview_iOS: NSObject, QLPreviewControllerDataSource, QLPreviewControllerDelegate {
    static let shared = QuickLookPreview_iOS()
    
    private var fileURL: URL?

    static func preview(url: URL) {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = scene.windows.first?.rootViewController else {
            return
        }
        shared.fileURL = url
        let previewController = QLPreviewController()
        previewController.dataSource = shared
        previewController.delegate = shared
        rootVC.present(previewController, animated: true)
    }

    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return fileURL == nil ? 0 : 1
    }

    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return fileURL! as NSURL
    }
}
#endif

#if os(macOS)
import AppKit
import Quartz

enum QuickLookPreview_macOS {
    static func preview(url: URL) {
        let panel = QLPreviewPanel.shared()
        panel?.makeKeyAndOrderFront(nil)
        panel?.dataSource = PreviewItemSource(url: url)
    }

    private class PreviewItemSource: NSObject, QLPreviewPanelDataSource {
        let url: URL

        init(url: URL) {
            self.url = url
        }

        func numberOfPreviewItems(in panel: QLPreviewPanel!) -> Int {
            return 1
        }

        func previewPanel(_ panel: QLPreviewPanel!, previewItemAt index: Int) -> QLPreviewItem! {
            return url as NSURL
        }
    }
}
#endif

