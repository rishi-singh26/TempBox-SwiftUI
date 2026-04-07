//
//  IAPManager.swift
//  TempBox
//
//  Created by Rishi Singh on 13/07/25.
//

import SwiftUI
import StoreKit

@MainActor
class IAPManager: ObservableObject {
    static let shared = IAPManager()

    @Published var availableProducts: [Product] = []
    @Published var isLoading: Bool = false

    @Published var loadProductsError: String? = nil
    @Published var purchaseError: String? = nil
    
    @AppStorage("hasTippedSmall") private(set) var hasTippedSmall: Bool = false
    @AppStorage("hasTippedMedium") private(set) var hasTippedMedium: Bool = false
    @AppStorage("hasTippedLarge") private(set) var hasTippedLarge: Bool = false
    @Published var hasTipped: Bool = false
    
    /// Replace with your actual product identifiers
    private let productIDs: [String] = [
        "com.rishi.TempMail.smallTip",
        "com.rishi.TempMail.mediumTip",
        "com.rishi.TempMail.largeTip2"
    ]
    
    func initialize() {
        Task {
            await loadProducts()
            await refreshPurchaseStatus()
            await listenForTransactionUpdates()
        }
    }

    func loadProducts() async {
        withAnimation {
            isLoading = true
        }
        defer {
            withAnimation {
                isLoading = false
            }
        }

        do {
            let products = try await Product.products(for: productIDs)
            
            availableProducts = products.sorted {
                guard let firstIndex = productIDs.firstIndex(of: $0.id), let secondIndex = productIDs.firstIndex(of: $1.id) else {
                    return false
                }
                return firstIndex < secondIndex
            }
        } catch {
            loadProductsError = "Failed to load products"
        }
    }

    func refreshPurchaseStatus() async {
        withAnimation {
            isLoading = true
        }
        defer {
            withAnimation {
                isLoading = false
            }
        }
        
        let randomDelay = Double.random(in: 0...2) // seconds
        try? await Task.sleep(nanoseconds: UInt64(randomDelay * 1_000_000_000))
        
        var unlockedIDs: [String] = []

        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               productIDs.contains(transaction.productID),
               transaction.revocationDate == nil {
                unlockedIDs.append(transaction.productID)
            }
        }

        updateUnlockedFeatures(for: unlockedIDs)
    }

    func purchase(product: Product) async {
        withAnimation {
            isLoading = true
        }
        defer {
            withAnimation {
                isLoading = false
            }
        }

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    await transaction.finish()
                    updateTipStatus(for: transaction.productID, status: true)
                case .unverified(_, let error):
                    purchaseError = "Purchase failed: Could not verify transaction. \(error.localizedDescription)"
                    updateTipStatus(for: product.id, status: false)
                }
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            purchaseError = "Purchase failed"
        }
    }

    private func listenForTransactionUpdates() async {
        for await result in Transaction.updates {
            if case .verified(let transaction) = result, productIDs.contains(transaction.productID) {
                await transaction.finish()
                updateTipStatus(for: transaction.productID, status: true)
            }
        }
    }

    func product(for id: String) -> Product? {
        availableProducts.first(where: { $0.id == id })
    }
    
    // Tipped features
    func updateTipStatus(for productId: String, status: Bool) {
        if productId.lowercased().contains("small") {
            hasTippedSmall = status
        } else if productId.lowercased().contains("medium") {
            hasTippedMedium = status
        } else if productId.lowercased().contains("large") {
            hasTippedLarge = status
        } else {
            // Nothing
        }
        
        withAnimation {
            hasTipped = hasTippedSmall || hasTippedMedium || hasTippedLarge
        }
    }
    
    func updateUnlockedFeatures(for productIds: [String]) {
        productIds.forEach { updateTipStatus(for: $0, status: true) }
    }
    
    func getTipStatus(for productId: String) -> Bool {
        if productId.lowercased().contains("small") {
            hasTippedSmall
        } else if productId.lowercased().contains("medium") {
            hasTippedMedium
        } else if productId.lowercased().contains("large") {
            hasTippedLarge
        } else {
            false
        }
    }
    
    func getTipMessage(for productId: String) -> String {
        if productId.lowercased().contains("small") {
            "Thank You!"
        } else if productId.lowercased().contains("medium") {
            "Awesome!"
        } else if productId.lowercased().contains("large") {
            "You rock!"
        } else {
            ""
        }
    }
}
