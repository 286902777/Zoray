import Foundation
import StoreKit

enum InAppPurchaseError: LocalizedError {
    case cannotMakePayments
    case productNotFound
    case productRequestFailed
    case purchaseFailed
    case pending
    case unverified

    var errorDescription: String? {
        switch self {
        case .cannotMakePayments:
            return "In-app purchases are not allowed."
        case .productNotFound:
            return "Product is unavailable."
        case .productRequestFailed:
            return "Failed to load product."
        case .purchaseFailed:
            return "Purchase failed."
        case .pending:
            return "Purchase is pending."
        case .unverified:
            return "Purchase verification failed."
        }
    }
}

struct InAppPurchaseResult {
    let didPurchase: Bool
    let receipt: String?
    let transactionId: String?
    let transaction: SKPaymentTransaction?
    let revenue: Double?
    let currency: String?
}

final class InAppPurchaseService: NSObject {
    static let shared = InAppPurchaseService()

    private var isObservingTransactions = false
    private var productsRequest: SKProductsRequest?
    private var productsRequestDelegate: ProductsRequestDelegate?
    private var purchaseContinuation: CheckedContinuation<InAppPurchaseResult, Error>?
    private var pendingProduct: SKProduct?

    private override init() {
        super.init()
    }

    func startTransactionUpdates() {
        guard !isObservingTransactions else { return }
        isObservingTransactions = true
        SKPaymentQueue.default().add(self)
    }

    @discardableResult
    func purchase(productId: String) async throws -> InAppPurchaseResult {
        guard SKPaymentQueue.canMakePayments() else {
            throw InAppPurchaseError.cannotMakePayments
        }

        startTransactionUpdates()

        let product = try await requestProduct(productId: productId)
        return try await withCheckedThrowingContinuation { continuation in
            purchaseContinuation = continuation
            pendingProduct = product
            SKPaymentQueue.default().add(SKPayment(product: product))
        }
    }

    private func requestProduct(productId: String) async throws -> SKProduct {
        try await withCheckedThrowingContinuation { continuation in
            let request = SKProductsRequest(productIdentifiers: [productId])
            let delegate = ProductsRequestDelegate { [weak self] result in
                self?.productsRequest = nil
                self?.productsRequestDelegate = nil

                switch result {
                case .success(let product):
                    continuation.resume(returning: product)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }

            productsRequest = request
            productsRequestDelegate = delegate
            request.delegate = delegate
            request.start()
        }
    }

    private func finishPurchasedTransaction(_ transaction: SKPaymentTransaction) {
        let product = pendingProduct
        pendingProduct = nil
        purchaseContinuation?.resume(
            returning: InAppPurchaseResult(
                didPurchase: true,
                receipt: currentAppStoreReceipt(),
                transactionId: transaction.transactionIdentifier,
                transaction: transaction,
                revenue: product?.price.doubleValue,
                currency: product?.priceLocale.currencyCode
            )
        )
        purchaseContinuation = nil
        SKPaymentQueue.default().finishTransaction(transaction)
    }

    private func cancelPurchase(_ transaction: SKPaymentTransaction) {
        pendingProduct = nil
        purchaseContinuation?.resume(
            returning: InAppPurchaseResult(
                didPurchase: false,
                receipt: nil,
                transactionId: nil,
                transaction: transaction,
                revenue: nil,
                currency: nil
            )
        )
        purchaseContinuation = nil
        SKPaymentQueue.default().finishTransaction(transaction)
    }

    private func failPurchase(_ transaction: SKPaymentTransaction) {
        pendingProduct = nil
        purchaseContinuation?.resume(throwing: transaction.error ?? InAppPurchaseError.purchaseFailed)
        purchaseContinuation = nil
        SKPaymentQueue.default().finishTransaction(transaction)
    }

    private func currentAppStoreReceipt() -> String? {
        guard let receiptURL = Bundle.main.appStoreReceiptURL,
              let receiptData = try? Data(contentsOf: receiptURL) else {
            return nil
        }

        return receiptData.base64EncodedString()
    }
}

extension InAppPurchaseService: SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased, .restored:
                finishPurchasedTransaction(transaction)
            case .failed:
                if (transaction.error as? SKError)?.code == .paymentCancelled {
                    cancelPurchase(transaction)
                } else {
                    failPurchase(transaction)
                }
            case .deferred:
                purchaseContinuation?.resume(throwing: InAppPurchaseError.pending)
                purchaseContinuation = nil
            case .purchasing:
                break
            @unknown default:
                failPurchase(transaction)
            }
        }
    }
}

private final class ProductsRequestDelegate: NSObject, SKProductsRequestDelegate {
    private let completion: (Result<SKProduct, Error>) -> Void

    init(completion: @escaping (Result<SKProduct, Error>) -> Void) {
        self.completion = completion
    }

    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        guard let product = response.products.first else {
            completion(.failure(InAppPurchaseError.productNotFound))
            return
        }

        completion(.success(product))
    }

    func request(_ request: SKRequest, didFailWithError error: Error) {
        completion(.failure(InAppPurchaseError.productRequestFailed))
    }
}
