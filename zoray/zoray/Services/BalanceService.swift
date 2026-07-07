import Foundation
import Security

extension Notification.Name {
    static let zorayBalanceDidChange = Notification.Name("zoray.balanceDidChange")
}

enum BalanceError: LocalizedError {
    case unavailableUser
    case keychainWriteFailed
    case insufficientBalance

    var errorDescription: String? {
        switch self {
        case .unavailableUser:
            return "Please log in first."
        case .keychainWriteFailed:
            return "Failed to update balance."
        case .insufficientBalance:
            return "Insufficient balance."
        }
    }
}

final class BalanceService {
    static let shared = BalanceService()

    private let keychainStore = KeychainBalanceStore()
    private let defaultBalance = 0
    private let defaultCatchBottleCount = 0
    private var cachedBalances: [String: Int] = [:]
    private var cachedCatchBottleCounts: [String: Int] = [:]

    private init() {}

    func currentBalance() -> Int {
        guard let userId = AuthService.shared.currentUser()?.id else {
            return 0
        }
        return balance(for: userId)
    }

    func balance(for userId: String) -> Int {
        if let cachedBalance = cachedBalances[userId] {
            return cachedBalance
        }

        let balance: Int
        if let storedBalance = keychainStore.loadValue(key: "balance", for: userId) {
            balance = storedBalance
        } else {
            balance = defaultBalance
            _ = keychainStore.saveValue(balance, key: "balance", for: userId)
        }
        cachedBalances[userId] = balance
        return balance
    }

    func currentCatchBottleCount() -> Int {
        guard let userId = AuthService.shared.currentUser()?.id else {
            return defaultCatchBottleCount
        }
        return catchBottleCount(for: userId)
    }

    func catchBottleCount(for userId: String) -> Int {
        if let cachedCount = cachedCatchBottleCounts[userId] {
            return cachedCount
        }

        let count: Int
        if let storedCount = keychainStore.loadValue(key: "catchBottleCount", for: userId) {
            count = storedCount
        } else {
            count = defaultCatchBottleCount
            _ = keychainStore.saveValue(count, key: "catchBottleCount", for: userId)
        }
        cachedCatchBottleCounts[userId] = count
        return count
    }

    func loadCurrentUserBalance() {
        guard let userId = AuthService.shared.currentUser()?.id else { return }
        let balance = balance(for: userId)
        postBalanceDidChange(userId: userId, balance: balance)
    }

    @discardableResult
    func addBalance(_ amount: Int, for userId: String) throws -> Int {
        let currentBalance = balance(for: userId)
        let newBalance = currentBalance + amount
        guard keychainStore.saveValue(newBalance, key: "balance", for: userId) else {
            throw BalanceError.keychainWriteFailed
        }

        cachedBalances[userId] = newBalance
        postBalanceDidChange(userId: userId, balance: newBalance)
        return newBalance
    }

    @discardableResult
    func purchaseCatchBottleChance(cost: Int = 200, for userId: String) throws -> Int {
        let currentBalance = balance(for: userId)
        guard currentBalance >= cost else {
            throw BalanceError.insufficientBalance
        }

        let newBalance = currentBalance - cost
        let newCount = catchBottleCount(for: userId) + 1
        guard keychainStore.saveValue(newBalance, key: "balance", for: userId),
              keychainStore.saveValue(newCount, key: "catchBottleCount", for: userId) else {
            throw BalanceError.keychainWriteFailed
        }

        cachedBalances[userId] = newBalance
        cachedCatchBottleCounts[userId] = newCount
        postBalanceDidChange(userId: userId, balance: newBalance)
        return newCount
    }

    private func postBalanceDidChange(userId: String, balance: Int) {
        NotificationCenter.default.post(
            name: .zorayBalanceDidChange,
            object: userId,
            userInfo: ["balance": balance]
        )
    }
}

private final class KeychainBalanceStore {
    private let service = "\(Bundle.main.bundleIdentifier ?? "zoray").balance"

    func loadValue(key: String, for userId: String) -> Int? {
        var query = baseQuery(key: key, for: userId)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess,
              let data = item as? Data,
              let value = String(data: data, encoding: .utf8),
              let balance = Int(value) else {
            return nil
        }
        return balance
    }

    func saveValue(_ value: Int, key: String, for userId: String) -> Bool {
        let data = Data("\(value)".utf8)
        let query = baseQuery(key: key, for: userId)
        let attributes: [String: Any] = [kSecValueData as String: data]

        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if updateStatus == errSecSuccess {
            return true
        }

        guard updateStatus == errSecItemNotFound else {
            return false
        }

        var addQuery = query
        addQuery[kSecValueData as String] = data
        return SecItemAdd(addQuery as CFDictionary, nil) == errSecSuccess
    }

    private func baseQuery(key: String, for userId: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "\(key).\(userId)"
        ]
    }
}
