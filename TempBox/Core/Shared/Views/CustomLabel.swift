//
//  CustomLabel.swift
//  i2048
//
//  Created by Rishi Singh on 19/12/24.
//

import SwiftUI

struct CustomLabel: View {
    /// system image name of leading icon
    var leadingImageName: String?
    /// system image name of trailing icon
    var trailingImageName: String?
    /// label title
    var title: String?

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            if let leadingImageName = leadingImageName, let title = title {
                Label(title, systemImage: leadingImageName)
            } else {
                if let leadingImageName = leadingImageName {
                    Image(systemName: leadingImageName)
                        .font(.title3)
                }
                if let title = title {
                    Text(title)
                        .font(.body)
                        .foregroundColor(.primary)
                }
            }
            Spacer()
            if let trailingImageName = trailingImageName {
                Image(systemName: trailingImageName)
                    .foregroundStyle(.gray.opacity(0.7))
                    .font(.footnote.bold())
            }
        }
        .padding(.vertical, 0)
    }
}

#Preview {
    List {
        CustomLabel(leadingImageName: "lock.open.display", trailingImageName: "arrow.up.right", title: "Open Source Code")
        CustomLabel(trailingImageName: "arrow.up.right", title: "Open Source Code")
        CustomLabel(leadingImageName: "lock.open.display", title: "Open Source Code")
        CustomLabel(leadingImageName: "lock.open.display", trailingImageName: "arrow.up.right")
    }
}
