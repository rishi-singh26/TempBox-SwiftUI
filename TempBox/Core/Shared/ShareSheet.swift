//
//  ShareSheet.swift
//  TempBox
//
//  Created by Rishi Singh on 16/06/25.
//

import SwiftUI

#if os(iOS)
import UIKit

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    let excludedActivityTypes: [UIActivity.ActivityType]?
    
    init(items: [Any], excludedActivityTypes: [UIActivity.ActivityType]? = nil) {
        self.items = items
        self.excludedActivityTypes = excludedActivityTypes
    }
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        controller.excludedActivityTypes = excludedActivityTypes
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No updates needed
    }
}

#elseif os(macOS)
import AppKit

struct ShareSheet: NSViewRepresentable {
    let items: [Any]
    
    init(items: [Any], excludedActivityTypes: [Any]? = nil) {
        self.items = items
        // Note: excludedActivityTypes not used on macOS
    }
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        // Trigger the share sheet when the view updates
        DispatchQueue.main.async {
            let picker = NSSharingServicePicker(items: items)
            picker.show(relativeTo: .zero, of: nsView, preferredEdge: .minY)
        }
    }
}
#endif
