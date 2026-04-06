//
//  MessagesViewModel.swift
//  TempBox
//
//  Created by Rishi Singh on 25/09/23.
//

import Foundation
import Observation

@Observable
class MessagesViewModel {
    var showingErrorAlert = false
    var errorAlertMessage = ""

    var searchText = ""

    var showDeleteMessageAlert = false
    var selectedMessForDeletion: Message?
}
