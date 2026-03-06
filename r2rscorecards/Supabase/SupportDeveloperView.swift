//
//  SupportDeveloperView.swift
//  r2rscorecards
//
//  Support the developer with optional tips
//

import SwiftUI
import StoreKit

struct SupportDeveloperView: View {
    @StateObject private var store = StoreKitManager()
    @Environment(\.dismiss) private var dismiss
    
    @State private var isPurchasing = false
    @State private var showThankYou = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "heart.circle.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.pink, .red],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Text("Support R2R Scorecards")
                            .font(.title.bold())
                        
                        Text("This app is completely free to use. If you find it valuable, consider supporting its development!")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 20)
                    
                    // What Your Support Does
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Your support helps:")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        SupportBenefit(
                            icon: "server.rack",
                            title: "Server & Database Costs",
                            description: "Keeping the app running smoothly"
                        )
                        
                        SupportBenefit(
                            icon: "sparkles",
                            title: "New Features",
                            description: "Adding more functionality you love"
                        )
                        
                        SupportBenefit(
                            icon: "wrench.and.screwdriver",
                            title: "Bug Fixes & Updates",
                            description: "Maintaining a great experience"
                        )
                        
                        SupportBenefit(
                            icon: "cup.and.saucer.fill",
                            title: "Developer Caffeine",
                            description: "Keeping me motivated! ☕️"
                        )
                    }
                    .padding(.vertical, 8)
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // Tip Options
                    VStack(spacing: 12) {
                        Text("Choose Your Support Level")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        if store.isLoading && store.products.isEmpty {
                            ProgressView("Loading options...")
                                .padding()
                        } else if store.products.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.largeTitle)
                                    .foregroundStyle(.orange)
                                Text("Unable to load tip options")
                                    .font(.headline)
                                Text("Please check your internet connection and try again")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Button("Retry") {
                                    Task {
                                        await store.loadProducts()
                                    }
                                }
                                .buttonStyle(.bordered)
                            }
                            .padding()
                        } else {
                            ForEach(store.products, id: \.id) { product in
                                TipOptionCard(
                                    product: product,
                                    isPurchasing: isPurchasing
                                ) {
                                    await purchaseProduct(product)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Privacy Note
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "lock.shield.fill")
                                .foregroundStyle(.green)
                            Text("Secure Payment")
                                .font(.caption.bold())
                            Spacer()
                        }
                        
                        Text("All payments are processed securely through Apple. Your payment information is never shared with the developer.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Thank You Note
                    Text("Every contribution, no matter the size, means the world to me. Thank you for using R2R Scorecards! 🙏")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                }
            }
            .navigationTitle("Support")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Thank You! 🎉", isPresented: $showThankYou) {
                Button("You're Welcome!") { }
            } message: {
                Text("Your support means everything! Thank you for helping keep R2R Scorecards running.")
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Purchase Action
    
    private func purchaseProduct(_ product: Product) async {
        isPurchasing = true
        defer { isPurchasing = false }
        
        do {
            let transaction = try await store.purchase(product)
            
            if transaction != nil {
                showThankYou = true
                
                // Optional: Track in analytics
                // Analytics.logEvent("tip_purchased", parameters: ["amount": product.displayPrice])
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

// MARK: - Support Benefit Row

struct SupportBenefit: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.bold())
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal)
    }
}

// MARK: - Tip Option Card

struct TipOptionCard: View {
    let product: Product
    let isPurchasing: Bool
    let onPurchase: () async -> Void
    
    // Get tip info from product ID
    private var tipInfo: (emoji: String, name: String, description: String) {
        if let tipProduct = TipProduct(rawValue: product.id) {
            return (tipProduct.emoji, tipProduct.displayName, tipProduct.description)
        }
        return ("💝", "Tip", "Support the developer")
    }
    
    var body: some View {
        Button {
            Task {
                await onPurchase()
            }
        } label: {
            HStack(spacing: 16) {
                // Emoji
                Text(tipInfo.emoji)
                    .font(.system(size: 40))
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(tipInfo.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Text(tipInfo.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Price
                VStack(alignment: .trailing, spacing: 2) {
                    Text(product.displayPrice)
                        .font(.title3.bold())
                        .foregroundStyle(.primary)
                    
                    if isPurchasing {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.blue)
                    }
                }
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .disabled(isPurchasing)
    }
}

// MARK: - Preview

#Preview {
    SupportDeveloperView()
}
