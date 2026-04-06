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
        MessateTile(
            circleColor: appStore.accentColor(colorScheme: colorScheme).opacity(message.seen == true ? 0 : 1),
            isRemovedFromRemote: message.isRemovedFromRemote,
            hasAttachments: message.hasAttachments,
            header: messageHeader,
            dateStr: message.createdAtFormatted,
            title: message.subject,
            subTitle: message.intro ?? "")
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

private struct MessateTile: View {
    var circleColor: Color
    var isRemovedFromRemote: Bool
    var hasAttachments: Bool
    var header: String
    var dateStr: String
    var title: String
    var subTitle: String
    
    var body: some View {
        HStack(alignment: .center) {
            VStack {
                Circle()
                    .fill(circleColor)
                    .frame(width: 12)
                
                Spacer()
                
                if isRemovedFromRemote {
                    Image(systemName: "icloud.slash")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 12, height: 12)
                        .foregroundColor(circleColor)
                }
            }
            .padding(.top, 6)
            .padding(.bottom, 4)
            
            VStack(alignment: .leading) {
                HStack {
                    Text(header)
                        .font(.headline)
                        .fontWeight(.bold)
                        .lineSpacing(1)
                    Spacer()
                    HStack {
                        Text(dateStr)
                            .foregroundColor(.secondary)
                        if hasAttachments {
                            Image(systemName: "paperclip")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 12, height: 12)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                Text(title)
                    .lineLimit(1, reservesSpace: true)
                Text(subTitle)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
    }
}

#Preview {
    List {
        MessateTile(
            circleColor: .blue,
            isRemovedFromRemote: true,
            hasAttachments: true,
            header: "Header",
            dateStr: "12th Apr 2026",
            title: "Message Subject",
            subTitle: "Message intorduction")
        MessateTile(
            circleColor: .blue,
            isRemovedFromRemote: true,
            hasAttachments: true,
            header: "Header",
            dateStr: "12th Apr 2026",
            title: "This is a logn Message Subject for testing alignemnt on mobile",
            subTitle: "This is a very long Message intorduction. This will be used for testing alignment of the into text on a message tile")
    }
    .listStyle(.plain)
}
