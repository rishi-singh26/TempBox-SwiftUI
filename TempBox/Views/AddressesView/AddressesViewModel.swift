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
    
    @Published var showDeleteAddressAlert = false
    @Published var selectedAddForDeletion: Address?
        
    @Published var showingErrorAlert = false
    @Published var errorAlertMessage = ""
    
    @Published var isAddressInfoSheetOpen = false
    var selectedAddForInfoSheet: Address?
    
    @Published var isEditAddressSheetOpen = false
    var selectedAddForEditSheet: Address?
    
    @Published var showSettingsSheet = false
        
    func openNewAddressSheet() {
        isNewAddressSheetOpen = true
    }
}
