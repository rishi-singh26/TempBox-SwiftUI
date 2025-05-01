//
//  Item.swift
//  TempMail
//
//  Created by Rishi Singh on 01/05/25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
