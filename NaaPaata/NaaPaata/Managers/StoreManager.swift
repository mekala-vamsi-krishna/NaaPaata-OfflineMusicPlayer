//
//  StoreManager.swift
//  NaaPaata
//
//  Created by Mekala Vamsi Krishna on 11/30/25.
//

import StoreKit
import SwiftUI
import Combine

@MainActor
final class StoreManager: ObservableObject {

    @Published private(set) var subscriptions: [Product] = []
    @Published private(set) var purchasedSubscriptions: [Product] = []
    @Published private(set) var isPremimumUser: Bool = false
    @Published private(set) var isPurchasing: Bool = false

    @Published var purchaseError: PurchaseError? = nil
    @Published var showRestoredAlert: Bool = false
    @Published var restoredMessage: String = ""

    private var updatesTask: Task<Void, Never>?
    private static let cacheKey = "isPremimumUser"

    /// True once a verified transaction has unlocked the flag during this
    /// app session. Prevents `refreshEntitlements()` from racing a fresh
    /// purchase and downgrading the flag back to false.
    private var unlockedThisSession = false

    init() {
        self.isPremimumUser = UserDefaults.standard.bool(forKey: Self.cacheKey)

        updatesTask = Task { [weak self] in
            for await update in StoreKit.Transaction.updates {
                guard let self else { return }
                await self.processTransactionUpdate(update)
            }
        }

        Task {
            await loadProducts()
            await refreshEntitlements()
        }
    }

    deinit {
        updatesTask?.cancel()
    }

    // MARK: - Products

    func loadProducts() async {
        do {
            let ids = ["Naa_Paata_1M", "Naa_Paata_6M", "Naa_Paata_12M"]
            let products = try await Product.products(for: ids)
            self.subscriptions = products.sorted(by: { $0.price < $1.price })
        } catch {
            print("[Store] loadProducts failed:", error)
            self.purchaseError = .loadProductsFailed(error.localizedDescription)
        }
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async {
        purchaseError = nil
        isPurchasing = true
        defer { isPurchasing = false }

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                await completePurchase(verification)
            case .userCancelled:
                break
            case .pending:
                break
            @unknown default:
                break
            }
        } catch {
            handlePurchaseError(error)
        }
    }

    private func completePurchase(
        _ verification: VerificationResult<StoreKit.Transaction>
    ) async {
        switch verification {

        case .verified(let transaction):
            // 1. Unlock immediately — this is the entitlement, nothing
            //    else needs to be checked.
            unlock()

            // 2. Track the product in the display array so any UI that
            //    reads `purchasedSubscriptions` is up to date.
            if let product = subscriptions.first(where: {
                $0.id == transaction.productID
            }), !purchasedSubscriptions.contains(where: { $0.id == product.id }) {
                purchasedSubscriptions.append(product)
            }

            // 3. Finish the transaction. StoreKit stops redelivering it.
            await transaction.finish()

            // ❌ NO `refreshEntitlements()` here. `currentEntitlements`
            //    doesn't reflect the just-finished transaction yet, and
            //    calling refresh would flip the flag back to false.

        case .unverified(let transaction, let error):
            print("[Store] Unverified transaction:", error)
            await transaction.finish()

            // StoreKit may still consider the entitlement active even if
            // the local signature check failed (sandbox quirk, network
            // glitch during cert refresh). Verify against the entitlement
            // list before giving up.
            for await entResult in StoreKit.Transaction.currentEntitlements {
                if case .verified(let entTxn) = entResult,
                   entTxn.productID == transaction.productID,
                   entTxn.revocationDate == nil {
                    unlock()
                    return
                }
            }

            purchaseError = .authenticationFailed
        }
    }

    // MARK: - Background transaction updates

    private func processTransactionUpdate(
        _ result: VerificationResult<StoreKit.Transaction>
    ) async {
        switch result {
        case .verified(let transaction):
            if transaction.revocationDate == nil {
                let isExpired = transaction.expirationDate.map { $0 < Date() } ?? false
                if !isExpired {
                    // Fresh purchase or renewal — unlock from the push
                    // channel. This typically fires BEFORE
                    // `product.purchase()` returns, so the UI updates
                    // within 1–3 seconds of the sheet dismissing.
                    unlock()

                    if let product = subscriptions.first(where: {
                        $0.id == transaction.productID
                    }), !purchasedSubscriptions.contains(where: { $0.id == product.id }) {
                        purchasedSubscriptions.append(product)
                    }
                } else {
                    // Subscription lapsed — safe to refresh.
                    await refreshEntitlements()
                }
            } else {
                // Refunded or revoked — safe to refresh.
                await refreshEntitlements()
            }

            await transaction.finish()

        case .unverified(_, let error):
            print("[Store] Background update unverified:", error)
            if case .unverified(let transaction, _) = result {
                await transaction.finish()
            }
        }
    }

    // MARK: - Entitlement refresh (cold launch + restore only)

    func refreshEntitlements() async {
        var activeProducts: [Product] = []
        var hasActive = false

        for await result in StoreKit.Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            if transaction.revocationDate != nil { continue }
            if let expiry = transaction.expirationDate, expiry < Date() { continue }

            hasActive = true

            if let product = subscriptions.first(where: {
                $0.id == transaction.productID
            }) {
                activeProducts.append(product)
            }
        }

        purchasedSubscriptions = activeProducts

        if hasActive {
            isPremimumUser = true
            unlockedThisSession = true
        } else if !unlockedThisSession {
            // Only reset if no purchase has happened this session. This
            // prevents a race where the entitlement hasn't propagated yet
            // but we already unlocked from a fresh purchase.
            isPremimumUser = false
        }
        // If unlockedThisSession is true but hasActive is false, we leave
        // the flag alone. It will reconcile on the next cold launch.

        UserDefaults.standard.set(isPremimumUser, forKey: Self.cacheKey)
    }

    // MARK: - Unlock

    private func unlock() {
        guard !isPremimumUser else { return }
        isPremimumUser = true
        unlockedThisSession = true
        UserDefaults.standard.set(true, forKey: Self.cacheKey)
        print("[Store] Unlocked premium")
    }

    // MARK: - Restore

    func restorePurchases() async {
        purchaseError = nil
        showRestoredAlert = false

        do {
            try await AppStore.sync()
            await refreshEntitlements()

            restoredMessage = isPremimumUser
                ? "Your purchases have been restored successfully."
                : "No previous purchases found to restore."
            showRestoredAlert = true
        } catch {
            print("[Store] Restore failed:", error)
            purchaseError = .unknown("Failed to restore purchases. Please try again.")
        }
    }

    // MARK: - Errors

    private func handlePurchaseError(_ error: Error) {
        print("[Store] Purchase threw:", error)

        if let storeError = error as? StoreKitError {
            switch storeError {
            case .userCancelled:
                return
            case .networkError:
                purchaseError = .networkError
            default:
                purchaseError = .unknown(storeError.localizedDescription)
            }
        } else {
            let nsError = error as NSError
            purchaseError = nsError.domain == NSURLErrorDomain
                ? .networkError
                : .unknown(error.localizedDescription)
        }
    }
}
