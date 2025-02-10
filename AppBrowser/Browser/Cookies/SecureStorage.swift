import Foundation
import Security
import CryptoKit

class SecureStorage {
    private let keyTag: String
    private var key: SymmetricKey?
    
    init() {
        let bundleID = Bundle.main.bundleIdentifier ?? "pl.maciejgad.AppBrowser"
        keyTag = "\(bundleID).cookies.encryptionKey"
    }
    
    func encrypt(data: Data) throws -> Data {
        let sealedBox = try AES.GCM.seal(data, using: getEncryptionKey())
        guard let combined = sealedBox.combined else {
            throw Error.noCombinedData
        }
        return combined
    }
    
    func decryp(data: Data) throws -> Data {
        let sealedBox = try AES.GCM.SealedBox(combined: data)
        let decryptedData = try AES.GCM.open(sealedBox, using: getEncryptionKey())
        return decryptedData
    }
    
    private func getEncryptionKey() -> SymmetricKey {
        if let key {
            return key
        }
        if let keyData = loadKeyFromKeychain() {
            let newKey = SymmetricKey(data: keyData)
            key = newKey
            return newKey
        } else {
            let newKey = SymmetricKey(size: .bits256)
            saveKeyToKeychain(key: newKey)
            key = newKey
            return newKey
        }
    }
    
    private func loadKeyFromKeychain() -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keyTag,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var data: AnyObject?
        if SecItemCopyMatching(query as CFDictionary, &data) == errSecSuccess {
            return data as? Data
        }
        return nil
    }
    
    
    private func saveKeyToKeychain(key: SymmetricKey) {
        let keyData = key.withUnsafeBytes { Data($0) }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keyTag,
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        SecItemAdd(query as CFDictionary, nil)
    }
    
    enum Error: Swift.Error {
        case noCombinedData
    }
}
