import Foundation
import StoreKit

enum InAppPurchaseError: LocalizedError {
    case productNotFound
    case pending
    case unverified

    var errorDescription: String? {
        switch self {
        case .productNotFound:
            return "Product is unavailable."
        case .pending:
            return "Purchase is pending."
        case .unverified:
            return "Purchase verification failed."
        }
    }
}

final class InAppPurchaseService {
    static let shared = InAppPurchaseService()

    private init() {}

    @discardableResult
    func purchase(productId: String) async throws -> Bool {
        let products = try await Product.products(for: [productId])
        guard let product = products.first else {
            throw InAppPurchaseError.productNotFound
        }

        let result = try await product.purchase()
        switch result {
        case .success(let verificationResult):
            let transaction = try checkVerified(verificationResult)
            await transaction.finish()
            return true
        case .userCancelled:
            return false
        case .pending:
            throw InAppPurchaseError.pending
        @unknown default:
            return false
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let safe):
            return safe
        case .unverified:
            throw InAppPurchaseError.unverified
        }
    }
}
