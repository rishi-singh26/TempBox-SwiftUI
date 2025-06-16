//
//  AboutView.swift
//  TempBox
//
//  Created by Rishi Singh on 02/05/25.
//

import SwiftUI
import StoreKit

struct AboutView: View {
    @EnvironmentObject private var settingsViewModel: SettingsViewModel
    
    var body: some View {
        #if os(macOS)
        MacOSAboutViewBuilder()
        #else
        IosAboutViewBuilder()
        #endif
    }
    
#if os(macOS)
    @ViewBuilder
    func MacOSAboutViewBuilder() -> some View {
        ScrollView {
            MacCustomSection(header: "") {
                HStack {
                    Image("PresentableIcon")
                        .resizable()
                        .frame(width: 70, height: 70)
                        .padding(.trailing, 15)
                    VStack(alignment: .leading) {
                        Text("TempBox")
                            .font(.largeTitle.bold())
                        Text("Version 2.0.1")
                            .font(.callout)
                        MarkdownLinkText(markdownText: "Powered by [mail.tm](https://www.mail.tm)")
                            .font(.callout)
                    }
                    Spacer()
                }
            }
            
            MacCustomSection {
                VStack(alignment: .leading) {
                    Button {
                        settingsViewModel.showLinkConfirmation(url: "https://letterbird.co/tempbox")
                    } label: {
                        CustomLabel(leadingImageName: "text.bubble", trailingImageName: "arrow.up.right", title: "Help & Support")
                    }
                    .buttonStyle(.link)
                    Divider()
                    Button {
                        getRating()
                    } label: {
                        CustomLabel(leadingImageName: "star", title: "Rate Us")
                    }
                    .buttonStyle(.link)
                    Divider()
                    Button {
                        openAppStoreReviewPage()
                    } label: {
                        CustomLabel(leadingImageName: "quote.bubble", trailingImageName: "arrow.up.right", title: "Write Review on App Store")
                    }
                    .buttonStyle(.link)
                }
            }
            
            MacCustomSection {
                VStack(alignment: .leading) {
                    Button {
                        settingsViewModel.showLinkConfirmation(url: "https://tempbox.rishisingh.in/privacy-policy.html")
                    } label: {
                        CustomLabel(leadingImageName: "lock.open.display", trailingImageName: "arrow.up.right", title: "Privacy Policy")
                    }
                    .buttonStyle(.link)
                    Divider()
                    Button {
                        settingsViewModel.showLinkConfirmation(url: "https://tempbox.rishisingh.in/terms-of-service.html")
                    } label: {
                        CustomLabel(leadingImageName: "list.bullet.rectangle.portrait", trailingImageName: "arrow.up.right", title: "Terms of Service")
                    }
                    .buttonStyle(.link)
                }
            }
            
//            MacCustomSection {
//                VStack(alignment: .leading) {
//                    Button {
//                        settingsViewModel.showLinkConfirmation(url: "https://github.com/rishi-singh26/TempBox-SwiftUI")
//                    } label: {
//                        CustomLabel(leadingImageName: "lock.open.display", trailingImageName: "arrow.up.right", title: "Source Code - Github")
//                    }
//                    .buttonStyle(.link)
//                    Divider()
//                    Button {
//                        settingsViewModel.showLinkConfirmation(url: "https://github.com/rishi-singh26/TempBox-SwiftUI/blob/main/LICENSE")
//                    } label: {
//                        CustomLabel(leadingImageName: "checkmark.seal.text.page", trailingImageName: "arrow.up.right", title: "MIT License")
//                    }
//                    .buttonStyle(.link)
//                }
//            }
            
//            MacCustomSection(header: "Copyright © 2025 Rishi Singh. All Rights Reserved.") {
            MacCustomSection {
                Button {
                    settingsViewModel.showLinkConfirmation(url: "https://tempbox.rishisingh.in")
                } label: {
                    CustomLabel(leadingImageName: "network", trailingImageName: "arrow.up.right", title: "https://tempbox.rishisingh.in")
                }
                .buttonStyle(.link)
            }
            .padding(.bottom, 50)
        }
    }
#endif
    
#if os(iOS)
    @ViewBuilder
    func IosAboutViewBuilder() -> some View {
        List {
            HStack {
                Image("PresentableIcon")
                    .resizable()
                    .frame(width: 70, height: 70)
                    .padding(.trailing, 15)
                VStack(alignment: .leading) {
                    Text("TempBox")
                        .font(.largeTitle.bold())
                    Text("Version 2.0.1")
                        .font(.callout)
                    MarkdownLinkText(markdownText: "Powered by [mail.tm](https://www.mail.tm)")
                        .font(.callout)
                }
            }
            
            Section {
                Button {
                    settingsViewModel.showLinkConfirmation(url: "https://letterbird.co/tempbox")
                } label: {
                    CustomLabel(leadingImageName: "text.bubble", trailingImageName: "arrow.up.right", title: "Help & Feedback")
                }
                Button {
                    getRating()
                } label: {
                    Label("Rate Us", systemImage: "star")
                }
                Button {
                    openAppStoreReviewPage()
                } label: {
                    CustomLabel(leadingImageName: "quote.bubble", trailingImageName: "arrow.up.right", title: "Write Review on App Store")
                }
            }
            
            Section {
                Button {
                    settingsViewModel.showLinkConfirmation(url: "https://tempbox.rishisingh.in/privacy-policy.html")
                } label: {
                    CustomLabel(leadingImageName: "lock.shield", trailingImageName: "arrow.up.right", title: "Privacy Policy")
                }
                Button {
                    settingsViewModel.showLinkConfirmation(url: "https://tempbox.rishisingh.in/terms-of-service.html")
                } label: {
                    CustomLabel(leadingImageName: "list.bullet.rectangle.portrait", trailingImageName: "arrow.up.right", title: "Terms of Service")
                }
            }
            
//            Section {
//                Button {
//                    settingsViewModel.showLinkConfirmation(url: "https://github.com/rishi-singh26/TempBox-SwiftUI")
//                } label: {
//                    CustomLabel(leadingImageName: "lock.open.display", trailingImageName: "arrow.up.right", title: "Source Code - Github")
//                }
//                Button {
//                    settingsViewModel.showLinkConfirmation(url: "https://github.com/rishi-singh26/TempBox-SwiftUI/blob/main/LICENSE")
//                } label: {
//                    CustomLabel(leadingImageName: "checkmark.seal.text.page", trailingImageName: "arrow.up.right", title: "MIT License")
//                }
//            }
            
//            Section("Copyright © 2025 Rishi Singh. All Rights Reserved.") {
            Section {
                Button {
                    settingsViewModel.showLinkConfirmation(url: "https://tempbox.rishisingh.in")
                } label: {
                    CustomLabel(leadingImageName: "network", trailingImageName: "arrow.up.right", title: "https://tempbox.rishisingh.in")
                }
            }
        }
    }
#endif
    
    func openAppStoreReviewPage() {
        let urlStr = "https://itunes.apple.com/app/id\(AppController.appId)?action=write-review"
        
        if let url = URL(string: urlStr) {
            url.open()
        }
    }
    
    func getRating() {
#if os(iOS)
        if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            AppStore.requestReview(in: scene)
        }
#elseif os(macOS)
        SKStoreReviewController.requestReview() // macOS doesn't need a scene
#elseif os(tvOS)
        SKStoreReviewController.requestReview() // tvOS doesn't need a scene
#elseif os(watchOS)
        // watchOS doesn't support SKStoreReviewController
        print("SKStoreReviewController not supported on watchOS")
#endif
    }
}

#Preview {
    AboutView()
}
