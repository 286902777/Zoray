import CoreTelephony
import CFNetwork
import Security
import UIKit

final class DeviceService {
    static let shared = DeviceService()

    static let deviceIDKey = "zoray.deviceID"
    static let UserTokenKey = "zoray.userToken"
    static let UserPassKey = "zoray.userPass"

    #if DEBUG
    static let appID = "44332211"
    #else
    static let appID = "40599851"
    #endif

    private let keychainStore = KeychainDeviceStore()

    var pushToken: String {
        get {
            return UserDefaults.standard.string(forKey: UserDefaultsKey.pushToken) ?? ""
        }
    }
    private init() {}

    struct AppModel {
        let name: String
        let scheme: String
    }

    // App name and URL scheme mappings.
    let appModels: [AppModel] = [
        AppModel(name: "WhatsApp", scheme: "whatsapp"),
        AppModel(name: "Instagram", scheme: "instagram"),
        AppModel(name: "TikTok", scheme: "tiktok"),
        AppModel(name: "GoogleMaps", scheme: "comgooglemaps"),
        AppModel(name: "Twitter", scheme: "tweetie"),
        AppModel(name: "QQ", scheme: "mqq"),
        AppModel(name: "WeChat", scheme: "wechat"),
        AppModel(name: "AliApp", scheme: "alipay"),
    ]

    // Returns installed supported apps.
    func getInstalledApps() -> [String] {
        var installedApps: [String] = []

        for app in appModels {
            if let url = URL(string: "\(app.scheme)://"), UIApplication.shared.canOpenURL(url) {
                installedApps.append(app.name)
            }
        }

        return installedApps
    }
    
    func saveUserToken(_ token: String) {
       _ = keychainStore.saveString(token, key: DeviceService.UserTokenKey)
    }
    
    func getUserToken() -> String {
        if let userToken = keychainStore.loadString(key: DeviceService.UserTokenKey), !userToken.isEmpty {
            return userToken
        } else {
            return ""
        }
    }
    
    func saveUserPassword(_ password: String) {
       _ = keychainStore.saveString(password, key: DeviceService.UserPassKey)
    }
    
    func getUserPassword() -> String {
        if let password = keychainStore.loadString(key: DeviceService.UserPassKey), !password.isEmpty {
            return password
        } else {
            return ""
        }
    }
    
    func getTimeZone() -> String {
        return TimeZone.current.identifier
    }
    
    func getLanguages() -> [String] {
        return Locale.preferredLanguages
    }
    
    func getKeyboards() -> [String] {
        var languages: [String] = []

        for mode in UITextInputMode.activeInputModes {
            if let lang = mode.primaryLanguage {
                languages.append(lang)
            }
        }
        return languages
    }
    
    func getDeviceID() -> String {
        if let existingID = keychainStore.loadString(key: DeviceService.deviceIDKey), !existingID.isEmpty {
            return existingID
        }

        let idfv = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        let deviceID = "\(idfv)\(DeviceService.appID)"
        _ = keychainStore.saveString(deviceID, key: DeviceService.deviceIDKey)

        return deviceID
    }

    func isSIMCardInserted() -> Bool {
        let networkInfo = CTTelephonyNetworkInfo()
        guard let carriers = networkInfo.serviceSubscriberCellularProviders else {
            return false
        }

        return carriers.values.contains { carrier in
            hasValue(carrier.mobileCountryCode)
                || hasValue(carrier.mobileNetworkCode)
                || hasValue(carrier.isoCountryCode)
                || hasValue(carrier.carrierName)
        }
    }

    func isVPNEnabled() -> Bool {
        guard let proxySettings = CFNetworkCopySystemProxySettings()?.takeRetainedValue() as? [String: Any],
              let scopedSettings = proxySettings["__SCOPED__"] as? [String: Any] else {
            return false
        }

        return scopedSettings.keys.contains { interfaceName in
            interfaceName.hasPrefix("utun")
                || interfaceName.hasPrefix("tun")
                || interfaceName.hasPrefix("tap")
                || interfaceName.hasPrefix("ppp")
                || interfaceName.hasPrefix("ipsec")
        }
    }

    private func hasValue(_ value: String?) -> Bool {
        guard let value else { return false }
        return !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

private final class KeychainDeviceStore {
    private let service = "\(Bundle.main.bundleIdentifier ?? "zoray").device"

    func loadString(key: String) -> String? {
        var query = baseQuery(key: key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess,
              let data = item as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }
        return value
    }

    func saveString(_ value: String, key: String) -> Bool {
        let data = Data(value.utf8)
        let query = baseQuery(key: key)
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

    private func baseQuery(key: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
    }
}
