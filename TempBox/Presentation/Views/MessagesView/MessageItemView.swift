//
//  MessageItemView.swift
//  TempBox
//
//  Created by Rishi Singh on 01/05/25.
//

import SwiftUI

struct MessageItemView: View {
    @Environment(\.colorScheme) var colorScheme

    @Environment(AddressStore.self) private var addressStore
    @Environment(MessagesViewModel.self) var controller
    @Environment(AppStore.self) private var appStore

    let message: Message

    private var messageHeader: String {
        if let name = message.fromName, !name.isEmpty {
            return name
        } else {
            return message.fromAddress
        }
    }

    var body: some View {
        Group {
#if os(iOS)
            Button {
                addressStore.selectedMessage = message
                appStore.path.append(message)
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
                .fill(appStore.accentColor(colorScheme: colorScheme).opacity(message.seen == true ? 0 : 1))
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
        let isSeen = message.seen
        Button {
            Task {
                await addressStore.updateMessageSeenStatus(messageData: message)
            }
        } label: {
            Label(isSeen ? unreadMessage : readMessage, systemImage: isSeen ? "envelope.badge.fill" : "envelope.open.fill")
        }
        .help("Toggle message read status")
        .tint(addTint ? .blue : nil)
    }

    @ViewBuilder
    private func BuildDeleteButton(addTint: Bool = true) -> some View {
        Button {
            controller.showDeleteMessageAlert = true
            controller.selectedMessForDeletion = message
        } label: {
            Label("Delete", systemImage: "trash")
        }
        .help("Permanently delete message")
        .tint(addTint ? .red : nil)
    }
}
