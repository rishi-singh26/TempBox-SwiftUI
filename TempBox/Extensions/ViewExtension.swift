//
//  ViewExtension.swift
//  TempBox
//
//  Created by Rishi Singh on 16/06/25.
//

import SwiftUI

extension View {
    func shareSheet(isPresented: Binding<Bool>, items: [Any], excludedActivityTypes: [Any]? = nil) -> some View {
        #if os(iOS)
        self.sheet(isPresented: isPresented) {
            ShareSheet(items: items, excludedActivityTypes: excludedActivityTypes as? [UIActivity.ActivityType])
        }
        #elseif os(macOS)
        self.background(
            EmptyView()
                .sheet(isPresented: isPresented) {
                    ShareSheet(items: items)
                        .frame(width: 1, height: 1) // Minimal frame for macOS
                }
        )
        #else
        self // For other platforms, return the view unchanged
        #endif
    }
    
    @ViewBuilder
    func sheetAppearanceSetup(tint: Color) -> some View {
        self
            .accentColor(tint)
            .presentationCornerRadius(25)
    }
}
