//
//  AddressesViewModel.swift
//  TempBox
//
//  Created by Rishi Singh on 01/05/25.
//

import Foundation
import Observation

@Observable
class AddressesViewModel {
    var foldersSectionExpanded: Bool = true
    var noFoldersSectionExpanded: Bool = true

    var searchText = ""
    var isNewAddressSheetOpen = false
    var isNewFolderSheetOpen = false
    var isQuickAddressSheetOpen = false

    var showDeleteAddressAlert = false
    var selectedAddForDeletion: Address?

    var showingErrorAlert = false
    var errorAlertMessage = ""

    var isAddressInfoSheetOpen = false
    var selectedAddForInfoSheet: Address?

    var isFolderInfoSheetOpen = false
    var selectedFolderForInfoSheet: Folder?

    var showSettingsSheet = false

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
