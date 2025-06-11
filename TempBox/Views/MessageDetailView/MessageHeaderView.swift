//
//  MessageHeaderView.swift
//  TempBox
//
//  Created by Rishi Singh on 01/05/25.
//

import SwiftUI

struct MessageHeaderView: View {
    let message: Message
    
    var messageFromHeader: String {
        message.fromName.isEmpty ? message.from.address : message.fromName
    }
    
    var messageFromSubHeader: String {
        message.fromName.isEmpty ? "" : message.from.address
    }
    var body: some View {
        
        HStack {
            Text((messageFromHeader).getInitials())
                .frame(width: 45, height: 45)
                .background(.blue)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 22.5))
                .padding(.horizontal, 5)
            VStack(alignment: .leading) {
                Text(messageFromHeader)
                    .font(.headline)
                Text(messageFromSubHeader)
                    .foregroundColor(.secondary)
                    .font(.caption)
                //                MarkdownLinkText(markdownText: "[\(message.data.from.address)](mailto:\(message.data.from.address))")
            }
            Spacer()
            Text(message.createdAtFormatted)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding([.vertical, .trailing], 5)
        .background(.thinMaterial)
    }
}

//#Preview {
//    MessageHeaderView()
//}
