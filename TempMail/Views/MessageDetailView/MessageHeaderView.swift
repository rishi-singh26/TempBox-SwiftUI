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
        message.data.from.name.isEmpty ? message.data.from.address : message.data.from.name
    }
    
    var messageFromSubHeader: String {
        message.data.from.name.isEmpty ? "" : message.data.from.address
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
                    .textSelection(.enabled)
            }
            Spacer()
            Text(message.data.createdAt.formatRelativeString(useTwentyFourHour: true))
                .foregroundColor(.secondary)
        }
        .padding([.vertical, .trailing], 5)
        .background(.thinMaterial)
    }
}

//#Preview {
//    MessageHeaderView()
//}
