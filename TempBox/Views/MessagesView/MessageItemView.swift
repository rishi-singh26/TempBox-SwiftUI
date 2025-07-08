//
//  MessageItemView.swift
//  TempBox
//
//  Created by Rishi Singh on 01/05/25.
//

import SwiftUI

struct MessageItemView: View {
    @EnvironmentObject private var addressesController: AddressesController
    @EnvironmentObject var controller: MessagesViewModel
    
    let message: Message
    let address: Address
    
    private var message2: Message? {
        addressesController.messageStore[address.id]?.messages.first { mes in
            mes.id == message.id
        }
    }
    
    var messageHeader: String {
        if let name = message2?.from.name, !name.isEmpty {
            return name
        } else {
            return message2?.from.address ?? ""
        }
    }
    
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Circle()
                .fill(.accent.opacity(message2?.seen == true ? 0 : 1))
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
            BuildStatusButton()
        }
        .swipeActions(edge: .trailing) {
            BuildDeleteButton()
        }
        .contextMenu {
            BuildStatusButton(addTint: false)
            Divider()
            BuildDeleteButton(addTint: false)
        }
    }
    
    @ViewBuilder
    func BuildStatusButton(addTint: Bool = true) -> some View {
        let unreadMessage = addTint ? "Unread" : "Mark as unread"
        let readMessage = addTint ? "Read" : "Mark as read"
        let isSeen = message2?.seen ?? false
        Button {
            Task {
                await addressesController.updateMessageSeenStatus(messageData: message, address: address, seen: !isSeen)
            }
        } label: {
            Label(message2?.seen == true ? unreadMessage : readMessage, systemImage: isSeen ? "envelope.badge.fill" : "envelope.open.fill")
        }
        .help("Toggle message read status")
        .tint(addTint ? nil : .blue)
    }
    
    @ViewBuilder
    func BuildDeleteButton(addTint: Bool = true) -> some View {
        Button {
            controller.showDeleteMessageAlert = true
            controller.selectedMessForDeletion = message
        } label: {
            Label("Delete", systemImage: "trash")
        }
        .help("Permanently delete message")
        .tint(addTint ? nil : .red)
    }
}


#Preview {
    ContentView()
        .environmentObject(AddressesController.shared)
}
