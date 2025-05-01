//
//  Message.swift
//  TempBox (macOS)
//
//  Created by Rishi Singh on 26/09/23.
//

import Foundation
import MailTMSwift

struct Message: Hashable, Identifiable {
    
    var isComplete: Bool = false
    var data: MTMessage
        
    var id: String {
        data.id
    }
    
    init(isComplete: Bool = false, data: MTMessage) {
        self.isComplete = isComplete
        self.data = data
    }
    
}

extension Message: Equatable {
    static func == (lhs: Message, rhs: Message) -> Bool {
        lhs.data.id == rhs.data.id
    }
}
