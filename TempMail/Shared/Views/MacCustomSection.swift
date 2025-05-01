//
//  MacCustomSection.swift
//  i2048
//
//  Created by Rishi Singh on 31/12/24.
//

import SwiftUI

struct MacCustomSection<Content: View>: View {
    let header: String?
    let footer: String?
    let content: Content
    
    init(
        header: String? = nil,
        footer: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.header = header
        self.footer = footer
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            if let safeHeader = header {
                Text(safeHeader)
                    .font(.caption2)
                    .textCase(.uppercase)
                    .padding([.top, .horizontal])
                    .padding(.horizontal)
            }
            GroupBox {
                VStack {
                    content
                }
                .padding(6)
            }
            .padding(.horizontal)
            if let safeFooter = footer {
                Text(safeFooter)
                    .font(.caption2)
                    .padding(.horizontal)
                    .padding(.horizontal)
            }
        }
    }
}

#Preview {
    MacCustomSection(header: "", footer: "") {
        CustomLabel(leadingImageName: "bolt.shield", trailingImageName: "chevron.right", title: "Privacy Policy")
    }
}
