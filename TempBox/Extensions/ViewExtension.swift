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
    
    
    // Added for onboarding view. Custom blur slide effect
    @ViewBuilder
    func blurSlide(_ show: Bool) -> some View {
        self
            // Groups the view and adds blur to the grouped view rather then applying blur to each node view
            .compositingGroup()
            .blur(radius: show ? 0 : 10)
            .opacity(show ? 1 : 0)
            .offset(y: show ? 0 : 100)
    }
    
    // Added for onboarding view. 
    @ViewBuilder
    func setUpOnboarding() -> some View {
#if os(macOS)
        self
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            .frame(minHeight: 600)
#else
        if UIDevice.current.userInterfaceIdiom == .pad {
            // Makiing it fit on iPadOS 18+ devices
            if #available(iOS 18, *) {
                self
                    .presentationSizing(.fitted)
                    .padding(.horizontal, 25)
                    .padding(.bottom, 25)
            } else {
                self
            }
        } else {
            self
        }
#endif
    }
}
