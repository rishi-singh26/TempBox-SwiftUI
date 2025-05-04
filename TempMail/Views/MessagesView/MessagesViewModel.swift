//
//  MessagesViewModel.swift
//  TempBox
//
//  Created by Rishi Singh on 25/09/23.
//

import Foundation

class MessagesViewModel: ObservableObject {
    @Published var messagesLoading = true
    @Published var messages = [Message]()
    
    @Published var showingErrorAlert = false
    @Published var errorAlertMessage = ""
    
    @Published var searchText = ""
    
    @Published var showDeleteMessageAlert = false
    @Published var selectedMessForDeletion: Message?
}
