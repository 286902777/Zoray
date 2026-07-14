import CommonCrypto
import Foundation

final class AESHelper {
    
#if DEBUG
    private static let key = "518486he8pzgbjsk"
    private static let iv = "614436p28qzhkjsl"
#else
    private static let key = "zt0i8g9hjapw1uke"
    private static let iv = "zelkpqg8wgo3agxp"
#endif

    private init() {}

    // MARK: - Public Methods +

    static func encrypt(_ plaintext: String) throws -> String {
        let data = Data(plaintext.utf8)
        let keyData = Data(key.utf8)
        let ivData = Data(iv.utf8)

        let encrypted = try aes(
            operation: CCOperation(kCCEncrypt),
            data: data,
            key: keyData,
            iv: ivData
        )

        return encrypted.hexString
    }

    static func decrypt(_ cipherHex: String) -> String {
        let cipherData = Data(hex: cipherHex)
        guard !cipherData.isEmpty else { return "" }

        let keyData = Data(key.utf8)
        let ivData = Data(iv.utf8)

        guard let decryptedData = try? aes(
            operation: CCOperation(kCCDecrypt),
            data: cipherData,
            key: keyData,
            iv: ivData
        ) else {
            return ""
        }

        return String(data: decryptedData, encoding: .utf8) ?? ""
    }

    // MARK: - Private Methods

    private static func aes(
        operation: CCOperation,
        data: Data,
        key: Data,
        iv: Data
    ) throws -> Data {
        var outLength = 0
        var outBytes = [UInt8](repeating: 0, count: data.count + kCCBlockSizeAES128)

        let status = CCCrypt(
            operation,
            CCAlgorithm(kCCAlgorithmAES),
            CCOptions(kCCOptionPKCS7Padding),
            [UInt8](key),
            key.count,
            [UInt8](iv),
            [UInt8](data),
            data.count,
            &outBytes,
            outBytes.count,
            &outLength
        )

        guard status == kCCSuccess else {
            throw NSError(domain: "AESHelper", code: Int(status))
        }

        return Data(bytes: outBytes, count: outLength)
    }
}

private extension Data {
    var hexString: String {
        map { String(format: "%02x", $0) }.joined()
    }

    init(hex: String) {
        self.init()
        var hex = hex
        while hex.count >= 2 {
            let byteString = hex.prefix(2)
            hex.removeFirst(2)

            var byte: UInt64 = 0
            if Scanner(string: String(byteString)).scanHexInt64(&byte) {
                append(UInt8(byte & 0xff))
            }
        }
    }
}
