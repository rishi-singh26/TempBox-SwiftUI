//
//  AddressesViewModel.swift
//  TempBox
//
//  Created by Rishi Singh on 01/05/25.
//

import Foundation

class AddressesViewModel: ObservableObject {
    static let shared = AddressesViewModel()
    
    @Published var searchText = ""
    @Published var isNewAddressSheetOpen = false
    
    @Published var showDeleteAccountAlert = false
    @Published var selectedAccForDeletion: Account?
        
    @Published var showingErrorAlert = false
    @Published var errorAlertMessage = ""
    
    @Published var isAccountInfoSheetOpen = false
    var selectedAccForInfoSheet: Account?
    
    @Published var isEditAccountSheetOpen = false
    var selectedAccForEditSheet: Account?
        
    func openNewAddressSheet() {
        isNewAddressSheetOpen = true
    }
}
