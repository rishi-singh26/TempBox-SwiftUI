//
//  MessageItemView.swift
//  TempBox
//
//  Created by Rishi Singh on 01/05/25.
//

import SwiftUI

struct MessageItemView: View {
    @EnvironmentObject private var addressesController: AddressesController
    @ObservedObject var controller: MessagesViewModel
    
    let message: Message
    let address: Address
    
    var messageHeader: String {
        if let name = message.from.name, !name.isEmpty {
            return name
        } else {
            return message.from.address
        }
    }
    
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Circle()
                .fill(.accent.opacity(message.seen ? 0 : 1))
                .frame(width: 12)
                .padding(0)
            VStack(alignment: .leading) {
                HStack {
                    Text(messageHeader)
                        .font(.headline)
                        .fontWeight(.bold)
                        .lineSpacing(1)
                    Spacer()
                    HStack {
                        Text(message.createdAtFormatted)
                            .foregroundColor(.secondary)
                        if message.hasAttachments {
                            Image(systemName: "paperclip")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 15, height: 15)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                Text(message.subject)
                    .lineLimit(1, reservesSpace: true)
                Text(message.intro ?? "")
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .swipeActions(edge: .leading) {
            Button {
                Task {
                    await addressesController.updateMessageSeenStatus(messageData: message, address: address, seen: !message.seen)
                }
            } label: {
                Label(message.seen ? "Unread" : "Read", systemImage: message.seen ? "envelope.badge.fill" : "envelope.open.fill")
            }
            .tint(.blue)
        }
        .swipeActions(edge: .trailing) {
            Button {
                controller.showDeleteMessageAlert = true
                controller.selectedMessForDeletion = message
            } label: {
                Label("Delete", systemImage: "trash")
            }
            .tint(.red)
        }
        .contextMenu {
            Button {
                Task {
                    await addressesController.updateMessageSeenStatus(messageData: message, address: address, seen: !message.seen)
                }
            } label: {
                Label(message.seen ? "Mark as unread" : "Mark as read", systemImage: message.seen ? "envelope.badge" : "envelope.open")
            }
            Divider()
            Button(role: .destructive) {
                controller.showDeleteMessageAlert = true
                controller.selectedMessForDeletion = message
            } label: {
                Label("Delete message", systemImage: "trash")
            }
        }
    }
}


#Preview {
    ContentView()
        .environmentObject(AddressesController.shared)
}
