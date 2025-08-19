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

                Text(NSLocalizedString("paywall_title", comment: ""))
                    .font(.title2).bold()

                Text(NSLocalizedString("paywall_subtitle", comment: ""))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.bottom, 12)

            // Feature list
            VStack(alignment: .leading, spacing: 10) {
                FeatureRow(icon: "square.grid.3x3.fill",
                           title: NSLocalizedString("feat_bigger_boards_title", comment: ""),
                           detail: NSLocalizedString("feat_bigger_boards_detail", comment: ""))
                FeatureRow(icon: "person.3.fill",
                           title: NSLocalizedString("feat_more_players_title", comment: ""),
                           detail: NSLocalizedString("feat_more_players_detail", comment: ""))
                FeatureRow(icon: "timer.square",
                           title: NSLocalizedString("feat_timer_title", comment: ""),
                           detail: NSLocalizedString("feat_timer_detail", comment: ""))
                FeatureRow(icon: "rectangle.and.pencil.and.ellipsis",
                           title: NSLocalizedString("feat_labels_title", comment: ""),
                           detail: NSLocalizedString("feat_labels_detail", comment: ""))
                FeatureRow(icon: "puzzlepiece.extension",
                           title: NSLocalizedString("feat_puzzles_title", comment: ""),
                           detail: NSLocalizedString("feat_puzzles_detail", comment: ""))
                FeatureRow(icon: "divide.square",
                           title: NSLocalizedString("feat_division_title", comment: ""),
                           detail: NSLocalizedString("feat_division_detail", comment: ""))
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
                    Text(NSLocalizedString("restore_purchases", comment: ""))
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(isRestoring || premiumUnlocked)
            .padding(.horizontal)
            .padding(.top, 8)

            // Small print
            VStack(spacing: 4) {
                Text(NSLocalizedString("paywall_smallprint", comment: ""))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                HStack(spacing: 12) {
                    Link(NSLocalizedString("privacy_policy", comment: ""),
                         destination: URL(string: "https://github.com/KuuuGR/Memul/wiki/POLICIES#privacy-policy-for-memul")!)
                    Link(NSLocalizedString("terms_of_use", comment: ""),
                         destination: URL(string: "https://github.com/KuuuGR/Memul/wiki/TERMS#terms-of-use-for-memul")!)
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
                Button(NSLocalizedString("close", comment: "")) { dismiss() }
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
        if premiumUnlocked {
            return NSLocalizedString("premium_unlocked_badge", comment: "")
        }
        if iap.isProductReady, !iap.premiumPriceText.isEmpty {
            let format = NSLocalizedString("unlock_premium_cta", comment: "")
            return "\(format) – \(iap.premiumPriceText)"
        }
        return NSLocalizedString("loading_price", comment: "")
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
