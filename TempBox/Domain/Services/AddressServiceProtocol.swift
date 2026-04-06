//
//  AddressServiceProtocol.swift
//  TempBox
//
//  Created by Rishi Singh on 06/04/26.
//

import Foundation

@MainActor
protocol AddressServiceProtocol {
    /// Returns all non-deleted addresses from local storage.
    func fetchAll() -> [Address]
    /// Checks whether the given email is unique. Returns (isUnique, isArchived).
    func isAddressUnique(email: String) -> (Bool, Bool)
    /// Creates and saves a new address from a freshly authenticated account.
    func addAddress(account: Account, token: String, password: String, name: String, folder: Folder?) async
    /// Authenticates and saves an address imported from a V1 export file.
    func loginAndSave(v1Address: ExportVersionOneAddress) async -> (Bool, String)
    /// Authenticates and saves an address imported from a V2 export file.
    func loginAndSave(v2Address: ExportVersionTwoAddress) async -> (Bool, String)
    /// Re-authenticates a soft-deleted / archived address and un-archives it.
    func loginAndRestore(_ address: Address) async -> (Bool, String)
    /// Persists non-relational edits to an address (e.g. name change).
    func updateAddress(_ address: Address)
    /// Soft-deletes an address (sets isDeleted = true).
    func deleteAddress(_ address: Address)
    /// Attempts to delete the account on the server, then hard-deletes locally.
    func deleteAddressFromServer(_ address: Address) async
    /// Hard-deletes an address from local storage.
    func permanentlyDelete(_ address: Address)
    /// Toggles the archived status of an address and removes it from any folder.
    func toggleArchiveStatus(_ address: Address) async
}
