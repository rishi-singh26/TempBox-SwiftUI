//
//  AboutView.swift
//  TempBox
//
//  Created by Rishi Singh on 02/05/25.
//

import SwiftUI

struct AboutView: View {
    var body: some View {
        #if os(macOS)
        MacOSAboutViewBuilder()
        #else
        IosAboutViewBuilder()
        #endif
    }
    
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
                VStack(alignment: .leading) {
                    Link(destination: URL(string: "https://tempbox.rishisingh.in/privacy-policy.html")!) {
                        CustomLabel(leadingImageName: "lock.open.display", trailingImageName: "arrow.up.right", title: "Privacy Policy")
                    }
                    Divider()
                    Link(destination: URL(string: "https://tempbox.rishisingh.in/terms-of-service.html")!) {
                        CustomLabel(leadingImageName: "list.bullet.rectangle.portrait", trailingImageName: "arrow.up.right", title: "Terms of Use")
                    }
                }
            }
            
            MacCustomSection {
                VStack(alignment: .leading) {
                    Link(destination: URL(string: "https://github.com/rishi-singh26/TempBox-SwiftUI")!) {
                        CustomLabel(leadingImageName: "lock.open.display", trailingImageName: "arrow.up.right", title: "Source Code - Github")
                    }
                    Divider()
                    Link(destination: URL(string: "https://github.com/rishi-singh26/TempBox-SwiftUI/blob/main/LICENSE")!) {
                        CustomLabel(leadingImageName: "checkmark.seal.text.page", trailingImageName: "arrow.up.right", title: "MIT License")
                    }
                }
            }
            
            MacCustomSection(header: "Copyright © 2025 Rishi Singh. All Rights Reserved.") {
                VStack(alignment: .leading) {
                    Link(destination: URL(string: "https://tempbox.rishisingh.in")!) {
                        CustomLabel(leadingImageName: "network", trailingImageName: "arrow.up.right", title: "https://tempbox.rishisingh.in")
                    }
                }
            }
            .padding(.bottom, 50)
        }
    }
    
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
                Link(destination: URL(string: "https://tempbox.rishisingh.in/privacy-policy.html")!) {
                    CustomLabel(leadingImageName: "lock.open.display", trailingImageName: "arrow.up.right", title: "Privacy Policy")
                }
                Link(destination: URL(string: "https://tempbox.rishisingh.in/terms-of-service.html")!) {
                    CustomLabel(leadingImageName: "list.bullet.rectangle.portrait", trailingImageName: "arrow.up.right", title: "Terms of Use")
                }
            }
            
            Section {
                Link(destination: URL(string: "https://github.com/rishi-singh26/TempBox-SwiftUI")!) {
                    CustomLabel(leadingImageName: "lock.open.display", trailingImageName: "arrow.up.right", title: "Source Code - Github")
                }
                Link(destination: URL(string: "https://github.com/rishi-singh26/TempBox-SwiftUI/blob/main/LICENSE")!) {
                    CustomLabel(leadingImageName: "checkmark.seal.text.page", trailingImageName: "arrow.up.right", title: "MIT License")
                }
            }
            
            Section("Copyright © 2025 Rishi Singh. All Rights Reserved.") {
                Link(destination: URL(string: "https://tempbox.rishisingh.in")!) {
                    CustomLabel(leadingImageName: "network", trailingImageName: "arrow.up.right", title: "https://tempbox.rishisingh.in")
                }
            }
        }
    }
}

#Preview {
    AboutView()
}
