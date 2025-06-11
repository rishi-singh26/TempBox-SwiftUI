//
//  MessageStore.swift
//  TempBox (macOS)
//
//  Created by Rishi Singh on 26/09/23.
//

import Foundation

struct MessageStore {
    var isFetching: Bool = false
    var error: String?
    var messages: [Message]
    
    var unreadMessagesCount: Int {
        return messages.filter { !$0.seen }.count
    }
}
