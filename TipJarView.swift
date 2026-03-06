//
//  TipJarView.swift
//  r2rscorecards
//
//  Created by PSL on 06/03/2026
//

import SwiftUI
import StoreKit

struct TipJarView: View {
    @StateObject private var store = StoreKitManager.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
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
                    
                    Text("This app is completely free!\nYour support helps me keep it running and add new features.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                
                // Tip Options
                VStack(spacing: 12) {
                    ForEach(store.products) { product in
                        TipButton(product: product) {
                            Task {
                                try? await store.purchase(product)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                // Thank You Message
                VStack(spacing: 8) {
                    Text("🥊 Thank You!")
                        .font(.headline)
                    
                    Text("Every contribution, big or small, means the world to me. You're helping keep boxing scoring accessible to everyone!")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("Tip Jar")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await store.loadProducts()
        }
    }
}

struct TipButton: View {
    let product: Product
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.displayName)
                        .font(.headline)
                    Text(product.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Text(product.displayPrice)
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        LinearGradient(
                            colors: [tipColor(for: product), tipColor(for: product).opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(8)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(.plain)
    }
    
    private func tipColor(for product: Product) -> Color {
        if product.id.contains("small") {
            return .green
        } else if product.id.contains("medium") {
            return .blue
        } else if product.id.contains("large") {
            return .purple
        } else {
            return .pink
        }
    }
}

#Preview {
    NavigationStack {
        TipJarView()
    }
}
