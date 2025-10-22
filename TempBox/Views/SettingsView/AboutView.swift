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
    @Environment(\.openURL) var openURL
    
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
        List {
            MacCustomSection {
                HStack {
                    Image("PresentableIcon")
                        .resizable()
                        .frame(width: 70, height: 70)
                        .padding(.trailing, 15)
                    VStack(alignment: .leading) {
                        Text("TempBox")
                            .font(.largeTitle.bold())
                        Text("v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "")")
                            .font(.callout)
                        MarkdownLinkText(markdownText: "Powered by [mail.tm](https://www.mail.tm)")
                            .font(.callout)
                    }
                    Spacer()
                }
            }
            .listRowSeparator(.hidden)
            
            MacCustomSection {
                VStack(alignment: .leading) {
                    Button {
                        openURL(url: "https://letterbird.co/tempbox")
                    } label: {
                        CustomLabel(leadingImageName: "text.bubble", trailingImageName: "arrow.up.right", title: "Help & Feedback")
                    }
                    .buttonStyle(.link)
                    .help("Open help and feedback form in web browser")
                    Divider()
                    Button {
                        getRating()
                    } label: {
                        CustomLabel(leadingImageName: "star", title: "Rate Us")
                    }
                    .buttonStyle(.link)
                    .help("Give star rating to TempBox")
                    Divider()
                    Button {
                        openAppStoreReviewPage()
                    } label: {
                        CustomLabel(leadingImageName: "quote.bubble", trailingImageName: "arrow.up.right", title: "Write Review on App Store")
                    }
                    .buttonStyle(.link)
                    .help("Write feedback for TempBox on AppStore")
                }
            }
            .listRowSeparator(.hidden)
            
            MacCustomSection {
                VStack(alignment: .leading) {
                    Button {
                        openURL(url: KPrivactPolicyURL)
                    } label: {
                        CustomLabel(leadingImageName: "lock.open.display", trailingImageName: "arrow.up.right", title: "Privacy Policy")
                    }
                    .buttonStyle(.link)
                    .help("Open TempBox privacy policy in web browser")
                    Divider()
                    Button {
                        openURL(url: KTermsOfServiceURL)
                    } label: {
                        CustomLabel(leadingImageName: "list.bullet.rectangle.portrait", trailingImageName: "arrow.up.right", title: "Terms of Service")
                    }
                    .buttonStyle(.link)
                    .help("Open TempBox terms of service in web browser")
                }
            }
            .listRowSeparator(.hidden)
            
            MacCustomSection {
                VStack(alignment: .leading) {
                    Button {
                        openURL(url: "https://github.com/rishi-singh26/TempBox-SwiftUI")
                    } label: {
                        CustomLabel(leadingImageName: "lock.open.display", trailingImageName: "arrow.up.right", title: "Source Code - Github")
                    }
                    .buttonStyle(.link)
                    .help("Open TempBox source code in safari")
                    Divider()
                    Button {
                        openURL(url: "https://github.com/rishi-singh26/TempBox-SwiftUI/blob/main/LICENSE")
                    } label: {
                        CustomLabel(leadingImageName: "checkmark.seal.text.page", trailingImageName: "arrow.up.right", title: "MIT License")
                    }
                    .buttonStyle(.link)
                    .help("Open TempBox Open-Source license in safari")
                }
            }
            .listRowSeparator(.hidden)
            
//            MacCustomSection(header: "Copyright © 2025 Rishi Singh. All Rights Reserved.") {
            MacCustomSection {
                VStack {
                    Button {
                        openURL(url: "https://tempbox.rishisingh.in")
                    } label: {
                        CustomLabel(leadingImageName: "network", trailingImageName: "arrow.up.right", title: "https://tempbox.rishisingh.in")
                    }
                    .buttonStyle(.link)
                    
                    Divider()
                    
                        .help("Visit TempBox website in safari")
                    Text("TempBox is lovingly developed in India. 🇮🇳")
                }
            }
            .listRowSeparator(.hidden)
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
                    Text("v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "")")
                        .font(.callout)
                    MarkdownLinkText(markdownText: "Powered by [mail.tm](https://www.mail.tm)")
                        .font(.callout)
                }
            }
            
            Section {
                Button {
                    openURL(url: "https://letterbird.co/tempbox")
                } label: {
                    CustomLabel(leadingImageName: "text.bubble", trailingImageName: "arrow.up.right", title: "Help & Feedback")
                }
                
                .help("Open help and feedback form in web browser")
                Button {
                    getRating()
                } label: {
                    Label("Rate Us", systemImage: "star")
                }
                .help("Give star rating to TempBox")
                Button {
                    openAppStoreReviewPage()
                } label: {
                    CustomLabel(leadingImageName: "quote.bubble", trailingImageName: "arrow.up.right", title: "Write Review on App Store")
                }
                .help("Write feedback for TempBox on AppStore")
            }
            
            Section {
                Button {
                    openURL(url: KPrivactPolicyURL)
                } label: {
                    CustomLabel(leadingImageName: "lock.shield", trailingImageName: "arrow.up.right", title: "Privacy Policy")
                }
                .help("Open TempBox privacy policy in web browser")
                Button {
                    openURL(url: KTermsOfServiceURL)
                } label: {
                    CustomLabel(leadingImageName: "list.bullet.rectangle.portrait", trailingImageName: "arrow.up.right", title: "Terms of Service")
                }
                .help("Open TempBox terms of service in web browser")
            }
            
            Section {
                Button {
                    openURL(url: "https://github.com/rishi-singh26/TempBox-SwiftUI")
                } label: {
                    CustomLabel(leadingImageName: "lock.open.display", trailingImageName: "arrow.up.right", title: "Source Code - Github")
                }
                .help("Open TempBox source code in safari")
                Button {
                    openURL(url: "https://github.com/rishi-singh26/TempBox-SwiftUI/blob/main/LICENSE")
                } label: {
                    CustomLabel(leadingImageName: "checkmark.seal.text.page", trailingImageName: "arrow.up.right", title: "MIT License")
                }
                .help("Open TempBox Open-Source license in safari")
            }
            
//            Section("Copyright © 2025 Rishi Singh. All Rights Reserved.") {
            Section {
                Button {
                    openURL(url: "https://tempbox.rishisingh.in")
                } label: {
                    CustomLabel(leadingImageName: "network", trailingImageName: "arrow.up.right", title: "https://tempbox.rishisingh.in")
                }
                .help("Visit TempBox website in safari")

                Text("TempBox is lovingly developed in India. 🇮🇳")
                    .font(.caption)
            }
        }
    }
#endif
    
    private func openAppStoreReviewPage() {
        let urlStr = "https://itunes.apple.com/app/id\(AppController.appId)?action=write-review"
        
        if let url = URL(string: urlStr) {
            url.open()
        }
    }
    
    private func getRating() {
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
    
    private func openURL(url: String) {
        if let url = URL(string: url) {
            openURL(url)
        }
    }
}

#Preview {
    AboutView()
}
