//
//  IAPManager.swift
//  Memul
//
//  Created by Grzegorz Kulesza on 19/08/2025.
//

import Foundation
import StoreKit
import Combine
import SwiftUI   // for @AppStorage

/// StoreKit 2 manager for a single non-consumable premium unlock.
/// - Works with a local `.storekit` file (debug) and App Store (release).
/// - Persists unlock to AppStorage so the app can flip `GameSettings.isPremium`.
@MainActor
final class IAPManager: ObservableObject {

    // MARK: - Singleton
    static let shared = IAPManager()

    // MARK: - Product identifiers
    private let premiumProductID = "com.etaosinapps.Memulx.premium"

    // MARK: - Published state
    @Published private(set) var premiumProduct: Product?

    /// Whether premium is unlocked for this Apple ID on this device.
    @AppStorage("premiumUnlocked") private(set) var premiumUnlocked: Bool = false {
        didSet { objectWillChange.send() }
    }

    @Published var lastErrorMessage: String?

    private var updateListenerTask: Task<Void, Never>?

    // MARK: - Init / Deinit

    private init() {
        Task { await loadProducts() }
        startTransactionListener()
        Task { await refreshEntitlements() }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Public API

    func configureOnLaunch() { }

    func loadProducts() async {
        do {
            let products = try await Product.products(for: [premiumProductID])
            premiumProduct = products.first
            lastErrorMessage = nil
        } catch {
            lastErrorMessage = "Failed to load products: \(error.localizedDescription)"
            premiumProduct = nil
        }
    }

    @discardableResult
    func purchasePremium() async -> Bool {
        guard let product = premiumProduct else {
            await loadProducts()
            guard let product = premiumProduct else {
                lastErrorMessage = "Product not available. Please try again."
                return false
            }
            return await purchase(product: product)
        }
        return await purchase(product: product)
    }

    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await refreshEntitlements()
            lastErrorMessage = nil
        } catch {
            lastErrorMessage = "Restore failed: \(error.localizedDescription)"
        }
    }

    func refreshEntitlements() async {
        var hasPremium = false
        for await result in StoreKit.Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            if transaction.productID == premiumProductID {
                hasPremium = (transaction.revocationDate == nil)
            }
        }
        setPremiumUnlocked(hasPremium)
    }

    // MARK: - Internal helpers

    private func purchase(product: Product) async -> Bool {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if let transaction: StoreKit.Transaction = try? checkVerified(verification) {
                    setPremiumUnlocked(true)
                    await transaction.finish()
                    lastErrorMessage = nil
                    return true
                } else {
                    lastErrorMessage = "Unable to verify purchase."
                    return false
                }

            case .userCancelled:
                lastErrorMessage = nil
                return false

            case .pending:
                lastErrorMessage = "Purchase pending approval."
                return false

            @unknown default:
                lastErrorMessage = "Unknown purchase result."
                return false
            }
        } catch {
            lastErrorMessage = "Purchase failed: \(error.localizedDescription)"
            return false
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let safe):
            return safe
        }
    }

    private func startTransactionListener() {
        updateListenerTask?.cancel()
        updateListenerTask = Task.detached { [weak self] in
            for await update in StoreKit.Transaction.updates {
                await self?.handle(transactionResult: update)
            }
        }
    }

    private func handle(transactionResult: VerificationResult<StoreKit.Transaction>) async {
        guard let safe: StoreKit.Transaction = try? checkVerified(transactionResult) else { return }
        if safe.productID == premiumProductID {
            let stillValid = (safe.revocationDate == nil)
            await MainActor.run { self.setPremiumUnlocked(stillValid) }
        }
        await safe.finish()
    }

    private func setPremiumUnlocked(_ newValue: Bool) {
        premiumUnlocked = newValue
    }
}

// MARK: - Convenience for views

extension IAPManager {
    var premiumPriceText: String {
        if let p = premiumProduct {
            return p.displayPrice
        }
        return ""
    }

    var isProductReady: Bool { premiumProduct != nil }
}
