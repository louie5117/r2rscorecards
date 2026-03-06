//
//  StoreKitManager.swift
//  r2rscorecards
//
//  Manages in-app purchases (tips/donations)
//

import Foundation
import StoreKit
import Combine

/// Product IDs for tips/donations
enum TipProduct: String, CaseIterable {
    case small = "com.r2rscorecards.tip.small"
    case medium = "com.r2rscorecards.tip.medium"
    case large = "com.r2rscorecards.tip.large"
    case generous = "com.r2rscorecards.tip.generous"
    
    var displayName: String {
        switch self {
        case .small: return "Small Tip"
        case .medium: return "Medium Tip"
        case .large: return "Large Tip"
        case .generous: return "Generous Tip"
        }
    }
    
    var emoji: String {
        switch self {
        case .small: return "☕️"
        case .medium: return "🍔"
        case .large: return "🍕"
        case .generous: return "🎉"
        }
    }
    
    var description: String {
        switch self {
        case .small: return "Buy me a coffee!"
        case .medium: return "Buy me lunch!"
        case .large: return "You're amazing!"
        case .generous: return "Incredible generosity!"
        }
    }
}

@MainActor
final class StoreKitManager: ObservableObject {
    
    static let shared = StoreKitManager()
    
    @Published var products: [Product] = []
    @Published var purchasedProductIDs: Set<String> = []
    @Published var isLoading = false
    @Published var lastError: String?
    
    private var updateListenerTask: Task<Void, Error>?
    
    private init() {
        // Start listening for transaction updates
        updateListenerTask = listenForTransactions()
        
        Task {
            await loadProducts()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - Load Products
    
    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Load products from App Store
            let productIDs = TipProduct.allCases.map { $0.rawValue }
            let storeProducts = try await Product.products(for: productIDs)
            
            // Sort by price
            products = storeProducts.sorted { $0.price < $1.price }
            
        } catch {
            lastError = "Failed to load products: \(error.localizedDescription)"
            print("❌ StoreKit Error: \(error)")
        }
    }
    
    // MARK: - Purchase
    
    func purchase(_ product: Product) async throws -> Transaction? {
        isLoading = true
        defer { isLoading = false }
        
        // Start the purchase
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            // Verify the transaction
            let transaction = try checkVerified(verification)
            
            // Deliver content (for consumables, just acknowledge)
            await transaction.finish()
            
            // Update purchased products
            await updatePurchasedProducts()
            
            return transaction
            
        case .userCancelled:
            lastError = "Purchase cancelled"
            return nil
            
        case .pending:
            lastError = "Purchase is pending approval"
            return nil
            
        @unknown default:
            lastError = "Unknown purchase result"
            return nil
        }
    }
    
    // MARK: - Transaction Verification
    
    func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
    
    // MARK: - Transaction Updates
    
    func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            // Iterate through any transactions that don't come from a direct call to `purchase()`
            for await result in Transaction.updates {
                do {
                    let transaction = try await MainActor.run {
                        try self.checkVerified(result)
                    }
                    
                    // Deliver content
                    await transaction.finish()
                    
                    // Update purchased products
                    await self.updatePurchasedProducts()
                } catch {
                    print("❌ Transaction verification failed: \(error)")
                }
            }
        }
    }
    
    // MARK: - Update Purchased Products
    
    func updatePurchasedProducts() async {
        var purchased: Set<String> = []
        
        // Iterate through all current entitlements
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else {
                continue
            }
            
            purchased.insert(transaction.productID)
        }
        
        purchasedProductIDs = purchased
    }
    
    // MARK: - Restore Purchases
    
    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await AppStore.sync()
            await updatePurchasedProducts()
        } catch {
            lastError = "Failed to restore purchases: \(error.localizedDescription)"
        }
    }
}

// MARK: - Errors

enum StoreError: Error, LocalizedError {
    case failedVerification
    
    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "Transaction verification failed"
        }
    }
}
