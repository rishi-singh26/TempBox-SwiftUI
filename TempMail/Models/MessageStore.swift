//
//  MessageStore.swift
//  TempBox (macOS)
//
//  Created by Rishi Singh on 26/09/23.
//

import Foundation
import MailTMSwift

struct MessageStore {
    var isFetching: Bool = false
    var error: MTError?
    var messages: [Message]
    
    var unreadMessagesCount: Int {
        return messages.filter { !$0.data.seen }.count
    }
}
