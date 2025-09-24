//
//  AddressesViewModel.swift
//  TempBox
//
//  Created by Rishi Singh on 01/05/25.
//

import Foundation

class AddressesViewModel: ObservableObject {
    static let shared = AddressesViewModel()
    
    @Published var foldersSectionExpanded: Bool = true
    @Published var noFoldersSectionExpanded: Bool = true
    
    @Published var searchText = ""
    @Published var isNewAddressSheetOpen = false
    @Published var isNewFolderSheetOpen = false
    @Published var isQuickAddressSheetOpen = false
    
    @Published var showDeleteAddressAlert = false
    @Published var selectedAddForDeletion: Address?
        
    @Published var showingErrorAlert = false
    @Published var errorAlertMessage = ""
    
    @Published var isAddressInfoSheetOpen = false
    var selectedAddForInfoSheet: Address?
    
    @Published var isFolderInfoSheetOpen = false
    var selectedFolderForInfoSheet: Folder?
    
    @Published var showSettingsSheet = false
    
    func openNewAddressSheet() {
        isNewAddressSheetOpen = true
    }
    func openNewFolderSheet() {
        isNewFolderSheetOpen = true
    }
    func openQuickAddressSheet() {
        isQuickAddressSheetOpen = true
    }
}
