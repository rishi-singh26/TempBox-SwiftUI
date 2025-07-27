//
//  MessageItemView.swift
//  TempBox
//
//  Created by Rishi Singh on 01/05/25.
//

import SwiftUI

struct MessageItemView: View {
    @Environment(\.colorScheme) var colorScheme
    
    @EnvironmentObject private var addressesController: AddressesController
    @EnvironmentObject var controller: MessagesViewModel
    @EnvironmentObject private var appController: AppController
    
    let message: Message
    let address: Address
    
    private var messageFromStore: Message? {
        addressesController.getMessageFromStore(address.id, message.id)
    }
    
    private var messageHeader: String {
        if let name = messageFromStore?.from.name, !name.isEmpty {
            return name
        } else {
            return messageFromStore?.from.address ?? ""
        }
    }
    
    var body: some View {
        Group {
#if os(iOS)
            Button {
                Task {
                    await addressesController.updateMessageSelection(message: message)
                }
                appController.path.append(message)
            } label: {
                MessageTileBuilder()
            }
#elseif os(macOS)
            MessageTileBuilder()
#endif
        }
        .swipeActions(edge: .leading) {
            BuildStatusButton()
        }
        .swipeActions(edge: .trailing) {
            BuildDeleteButton()
        }
        .contextMenu {
            BuildStatusButton(addTint: false)
            BuildDeleteButton(addTint: false)
        }
    }
    
    @ViewBuilder
    private func MessageTileBuilder() -> some View {
        HStack(alignment: .firstTextBaseline) {
            Circle()
                .fill(appController.accentColor(colorScheme: colorScheme).opacity(messageFromStore?.seen == true ? 0 : 1))
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
    }
    
    @ViewBuilder
    private func BuildStatusButton(addTint: Bool = true) -> some View {
        let unreadMessage = addTint ? "Unread" : "Mark as unread"
        let readMessage = addTint ? "Read" : "Mark as read"
        let isSeen = messageFromStore?.seen ?? false
        Button {
            Task {
                await addressesController.updateMessageSeenStatus(messageData: message, address: address)
            }
        } label: {
            Label(messageFromStore?.seen == true ? unreadMessage : readMessage, systemImage: isSeen ? "envelope.badge.fill" : "envelope.open.fill")
        }
        .help("Toggle message read status")
        .tint(addTint ? .blue : nil)
    }
    
    @ViewBuilder
    private func BuildDeleteButton(addTint: Bool = true) -> some View {
        Button {
            controller.showDeleteMessageAlert = true
            controller.selectedMessForDeletion = message
            controller.selectedAddForMessDeletion = address
        } label: {
            Label("Delete", systemImage: "trash")
        }
        .help("Permanently delete message")
        .tint(addTint ? .red : nil)
    }
}


#Preview {
    ContentView()
        .environmentObject(AddressesController.shared)
}
