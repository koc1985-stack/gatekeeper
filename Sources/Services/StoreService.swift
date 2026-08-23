import Foundation
import StoreKit

enum StoreError: Error {
    case failedVerification
}

/// Thin StoreKit 2 wrapper: loads the premium products, runs purchases, and tracks
/// the current entitlement. Test locally via Resources/Configuration.storekit.
@Observable
final class StoreService {
    static let shared = StoreService()

    static let productIDs = [
        "com.impulsegatekeeper.premium.lifetime"
    ]

    private(set) var products: [Product] = []
    private(set) var isPremium: Bool = false

    private var transactionListener: Task<Void, Never>?

    private init() {
        transactionListener = listenForTransactions()
        Task {
            await loadProducts()
            await refreshEntitlements()
        }
    }

    deinit {
        transactionListener?.cancel()
    }

    func loadProducts() async {
        guard let fetched = try? await Product.products(for: Self.productIDs) else {
            products = []
            return
        }
        products = fetched.sorted { $0.price < $1.price }
    }

    @discardableResult
    func purchase(_ product: Product) async throws -> Bool {
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            await refreshEntitlements()
            return true
        case .userCancelled, .pending:
            return false
        @unknown default:
            return false
        }
    }

    func restore() async {
        try? await AppStore.sync()
        await refreshEntitlements()
    }

    func refreshEntitlements() async {
        var active = false
        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result), transaction.revocationDate == nil {
                active = true
            }
        }
        isPremium = active
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached {
            for await result in Transaction.updates {
                guard let transaction = try? self.checkVerified(result) else { continue }
                await transaction.finish()
                await self.refreshEntitlements()
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
}
