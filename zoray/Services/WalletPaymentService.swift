import Foundation

struct WalletPaymentPackage {
    let amount: String
    let price: String
    let productId: String
}

enum WalletPaymentResult {
    case success(receipt: String?)
    case cancelled
}

enum WalletPaymentError: LocalizedError {
    case loginRequired
    case invalidProductAmount
    
    var errorDescription: String? {
        switch self {
        case .loginRequired:
            return "Please log in first."
        case .invalidProductAmount:
            return "Invalid product amount."
        }
    }
}

final class WalletPaymentService {
    static let shared = WalletPaymentService()
    
    let packages: [WalletPaymentPackage] = [
        WalletPaymentPackage(amount: "400", price: "$0.99", productId: "sbmsikozsyuqqaer"),
        WalletPaymentPackage(amount: "800", price: "$1.99", productId: "ixgzymtqrarbfxsv"),
        WalletPaymentPackage(amount: "1780", price: "$3.99", productId: "kibtegfnvwlsaxsi"),
        WalletPaymentPackage(amount: "2450", price: "$4.99", productId: "yyghcucayukndkcb"),
//        WalletPaymentPackage(amount: "2450", price: "$4.99", productId: "dxismgcwewhrtezo"),//dxismgcwewhrtezo
        WalletPaymentPackage(amount: "5150", price: "$9.99", productId: "ppametlxzpksjplo"),
        WalletPaymentPackage(amount: "10800", price: "$19.99", productId: "zfwdfihxrathvrlh"),
        WalletPaymentPackage(amount: "19800", price: "$39.99", productId: "fmravldlhofgsixb"),
        WalletPaymentPackage(amount: "29400", price: "$49.99", productId: "vmmunujhdatmyoqe"),
        WalletPaymentPackage(amount: "34500", price: "$69.99", productId: "kefrldtwdiopynog"),
        WalletPaymentPackage(amount: "63700", price: "$99.99", productId: "csusqrpcarunpkaq")
    ]
    
    private init() {}
    
    func purchase(_ package: WalletPaymentPackage) async throws -> WalletPaymentResult {
        guard let currentUser = AuthService.shared.currentUser() else {
            throw WalletPaymentError.loginRequired
        }
        
        guard let amount = Int(package.amount) else {
            throw WalletPaymentError.invalidProductAmount
        }
        
        let purchaseResult = try await InAppPurchaseService.shared.purchase(productId: package.productId)
        guard purchaseResult.didPurchase else { return .cancelled }

        try await MainActor.run {
            try BalanceService.shared.addBalance(amount, for: currentUser.id)
        }
        return .success(receipt: purchaseResult.receipt)
    }
    
    func handleRechargeCallback(
        batchNo: String,
        orderCode: String,
        receipt: String,
        revenue: Double? = nil,
        currency: String? = nil
    ) {
        RouteManager.shared.payRequest(batchNo, orderCode, receipt, revenue: revenue, currency: currency)
    }
}
