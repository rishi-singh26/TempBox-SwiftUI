//
//  AboutView.swift
//  TempBox
//
//  Created by Rishi Singh on 02/05/25.
//

import SwiftUI

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
                        Text("Version 2.0.0")
                            .font(.callout)
                        MarkdownLinkText(markdownText: "Powered by [mail.tm](https://www.mail.tm)")
                            .font(.callout)
                    }
                    Spacer()
                }
            }
            
            MacCustomSection {
                Button {
                    settingsViewModel.linkToOpen = "https://letterbird.co/tempbox"
                    settingsViewModel.showLinkOpenConfirmation.toggle()
                } label: {
                    CustomLabel(leadingImageName: "text.bubble", trailingImageName: "arrow.up.right", title: "Help & Feedback")
                }
                .buttonStyle(.link)
            }
            
            MacCustomSection {
                VStack(alignment: .leading) {
                    Button {
                        settingsViewModel.linkToOpen = "https://tempbox.rishisingh.in/privacy-policy.html"
                        settingsViewModel.showLinkOpenConfirmation.toggle()
                    } label: {
                        CustomLabel(leadingImageName: "lock.open.display", trailingImageName: "arrow.up.right", title: "Privacy Policy")
                    }
                    .buttonStyle(.link)
                    Divider()
                    Button {
                        settingsViewModel.linkToOpen = "https://tempbox.rishisingh.in/terms-of-service.html"
                        settingsViewModel.showLinkOpenConfirmation.toggle()
                    } label: {
                        CustomLabel(leadingImageName: "list.bullet.rectangle.portrait", trailingImageName: "arrow.up.right", title: "Terms of Service")
                    }
                    .buttonStyle(.link)
                }
            }
            
            MacCustomSection {
                VStack(alignment: .leading) {
                    Button {
                        settingsViewModel.linkToOpen = "https://github.com/rishi-singh26/TempBox-SwiftUI"
                        settingsViewModel.showLinkOpenConfirmation.toggle()
                    } label: {
                        CustomLabel(leadingImageName: "lock.open.display", trailingImageName: "arrow.up.right", title: "Source Code - Github")
                    }
                    .buttonStyle(.link)
                    Divider()
                    Button {
                        settingsViewModel.linkToOpen = "https://github.com/rishi-singh26/TempBox-SwiftUI/blob/main/LICENSE"
                        settingsViewModel.showLinkOpenConfirmation.toggle()
                    } label: {
                        CustomLabel(leadingImageName: "checkmark.seal.text.page", trailingImageName: "arrow.up.right", title: "MIT License")
                    }
                    .buttonStyle(.link)
                }
            }
            
            MacCustomSection(header: "Copyright © 2025 Rishi Singh. All Rights Reserved.") {
                Button {
                    settingsViewModel.linkToOpen = "https://tempbox.rishisingh.in"
                    settingsViewModel.showLinkOpenConfirmation.toggle()
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
                    Text("Version 2.0.0")
                        .font(.callout)
                    MarkdownLinkText(markdownText: "Powered by [mail.tm](https://www.mail.tm)")
                        .font(.callout)
                }
            }
            
            Section {
                Button {
                    settingsViewModel.linkToOpen = "https://letterbird.co/tempbox"
                    settingsViewModel.showLinkOpenConfirmation.toggle()
                } label: {
                    CustomLabel(leadingImageName: "text.bubble", trailingImageName: "arrow.up.right", title: "Help & Feedback")
                }
            }
            
            Section {
                Button {
                    settingsViewModel.linkToOpen = "https://tempbox.rishisingh.in/privacy-policy.html"
                    settingsViewModel.showLinkOpenConfirmation.toggle()
                } label: {
                    CustomLabel(leadingImageName: "lock.open.display", trailingImageName: "arrow.up.right", title: "Privacy Policy")
                }
                Button {
                    settingsViewModel.linkToOpen = "https://tempbox.rishisingh.in/terms-of-service.html"
                    settingsViewModel.showLinkOpenConfirmation.toggle()
                } label: {
                    CustomLabel(leadingImageName: "list.bullet.rectangle.portrait", trailingImageName: "arrow.up.right", title: "Terms of Service")
                }
            }
            
            Section {
                Button {
                    settingsViewModel.linkToOpen = "https://github.com/rishi-singh26/TempBox-SwiftUI"
                    settingsViewModel.showLinkOpenConfirmation.toggle()
                } label: {
                    CustomLabel(leadingImageName: "lock.open.display", trailingImageName: "arrow.up.right", title: "Source Code - Github")
                }
                Button {
                    settingsViewModel.linkToOpen = "https://github.com/rishi-singh26/TempBox-SwiftUI/blob/main/LICENSE"
                    settingsViewModel.showLinkOpenConfirmation.toggle()
                } label: {
                    CustomLabel(leadingImageName: "checkmark.seal.text.page", trailingImageName: "arrow.up.right", title: "MIT License")
                }
            }
            
            Section("Copyright © 2025 Rishi Singh. All Rights Reserved.") {
                Button {
                    settingsViewModel.linkToOpen = "https://tempbox.rishisingh.in"
                    settingsViewModel.showLinkOpenConfirmation.toggle()
                } label: {
                    CustomLabel(leadingImageName: "network", trailingImageName: "arrow.up.right", title: "https://tempbox.rishisingh.in")
                }
            }
        }
    }
#endif
}

#Preview {
    AboutView()
}
