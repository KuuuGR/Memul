//
//  PaywallView.swift
//  Memul
//
//  Created by Grzegorz Kulesza on 19/08/2025.
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    // Inject your settings so we can flip isPremium on unlock
    @Binding var settings: GameSettings

    // IAP state
    @ObservedObject private var iap = IAPManager.shared
    @AppStorage("premiumUnlocked") private var premiumUnlocked: Bool = false

    @Environment(\.dismiss) private var dismiss
    @State private var isPurchasing = false
    @State private var isRestoring = false

    var body: some View {
        VStack(spacing: 0) {
            // Header / artwork
            VStack(spacing: 12) {
                Image(systemName: "seal.checkmark.fill")
                    .font(.system(size: 48, weight: .semibold))
                    .foregroundStyle(.yellow)
                    .padding(.top, 24)

                Text("Memul Premium")
                    .font(.title2).bold()

                Text("Unlock all features and remove free limits.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.bottom, 12)

            // Feature list
            VStack(alignment: .leading, spacing: 10) {
                FeatureRow(icon: "square.grid.3x3.fill", title: "Bigger boards", detail: "Up to 33×33")
                FeatureRow(icon: "person.3.fill",      title: "More players", detail: "Up to 32 players")
                FeatureRow(icon: "timer.square",       title: "Turn timer",   detail: "∞ / 30 / 60 / 120 seconds")
                FeatureRow(icon: "rectangle.and.pencil.and.ellipsis", title: "Label styling", detail: "Colors & positions")
                FeatureRow(icon: "puzzlepiece.extension", title: "Full puzzle set", detail: "Free + premium images")
                FeatureRow(icon: "divide.square",      title: "Quick Division", detail: "Unlock division mode")
            }
            .padding(.horizontal)
            .padding(.top, 8)

            Spacer(minLength: 16)

            // Error line (if any)
            if let err = iap.lastErrorMessage, !err.isEmpty {
                Text(err)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
            }

            // Purchase button
            Button(action: buyTapped) {
                HStack {
                    if isPurchasing { ProgressView().padding(.trailing, 6) }
                    Text(purchaseButtonTitle())
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
            .disabled(isPurchasing || premiumUnlocked || !iap.isProductReady)
            .padding(.horizontal)
            .padding(.top, 6)

            // Restore button
            Button(action: restoreTapped) {
                HStack {
                    if isRestoring { ProgressView().padding(.trailing, 6) }
                    Text("Restore Purchases")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(isRestoring || premiumUnlocked)
            .padding(.horizontal)
            .padding(.top, 8)

            // Small print
            VStack(spacing: 4) {
                Text("One-time purchase. Family Sharing supported. Your purchase is linked to your Apple ID.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                // Replace with your actual links if you have a webpage
                HStack(spacing: 12) {
                    Link("Privacy Policy", destination: URL(string: "https://github.com/KuuuGR/Memul/wiki/POLICIES#privacy-policy-for-memul")!)
                    Link("Terms of Use",   destination: URL(string: "https://github.com/KuuuGR/Memul/wiki/TERMS#terms-of-use-for-memul")!)
                }
                .font(.caption2)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .background(Color(UIColor.systemBackground))
        .task {
            // Ensure product is loaded for price text
            await iap.loadProducts()
        }
        .onChange(of: premiumUnlocked) { _, newValue in
            if newValue {
                // Flip settings, relax limits immediately
                settings.isPremium = true
                // Optional: auto-dismiss paywall when purchased
                dismiss()
            }
        }
        .onAppear {
            // Keep settings in sync if the flag is already true
            if premiumUnlocked { settings.isPremium = true }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Close") { dismiss() }
            }
        }
    }

    // MARK: - Actions

    private func buyTapped() {
        guard !isPurchasing else { return }
        isPurchasing = true
        Task {
            _ = await iap.purchasePremium()
            isPurchasing = false
        }
    }

    private func restoreTapped() {
        guard !isRestoring else { return }
        isRestoring = true
        Task {
            await iap.restorePurchases()
            isRestoring = false
        }
    }

    // MARK: - UI helpers

    private func purchaseButtonTitle() -> String {
        if premiumUnlocked { return "Premium Unlocked" }
        if iap.isProductReady, !iap.premiumPriceText.isEmpty {
            return "Unlock Premium – \(iap.premiumPriceText)"
        }
        return "Loading price…"
    }
}

// MARK: - Small feature row component (inline to keep one file)

private struct FeatureRow: View {
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Image(systemName: icon)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline).bold()
                Text(detail).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.06)))
    }
}
