import Foundation
import Security

enum KeychainError: Error, LocalizedError {
    case unexpectedStatus(OSStatus)
    case dataConversionFailure

    var errorDescription: String? {
        switch self {
        case .unexpectedStatus(let s): return "Keychain error (\(s))"
        case .dataConversionFailure: return "Keychain data conversion failure"
        }
    }
}

protocol KeychainServicing {
    func save(_ value: String, for key: String) throws
    func read(_ key: String) throws -> String?
    func delete(_ key: String) throws
}

/// Stores Alpaca API credentials in the iOS Keychain.
///
/// Items are scoped to this app via `kSecAttrService` and only accessible after
/// first device unlock. Using `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`
/// avoids syncing credentials to iCloud Keychain.
final class KeychainService: KeychainServicing {
    static let shared = KeychainService()

    static let apiKeyIdentifier = "alpaca.api.key.id"
    static let apiSecretIdentifier = "alpaca.api.secret.key"

    private let service: String

    init(service: String = Bundle.main.bundleIdentifier ?? "ETFTrader") {
        self.service = service
    }

    private func baseQuery(_ key: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
    }

    func save(_ value: String, for key: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.dataConversionFailure
        }

        var query = baseQuery(key)
        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        let status = SecItemCopyMatching(query as CFDictionary, nil)
        switch status {
        case errSecSuccess:
            let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
            guard updateStatus == errSecSuccess else {
                throw KeychainError.unexpectedStatus(updateStatus)
            }
        case errSecItemNotFound:
            query.merge(attributes) { _, new in new }
            let addStatus = SecItemAdd(query as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                throw KeychainError.unexpectedStatus(addStatus)
            }
        default:
            throw KeychainError.unexpectedStatus(status)
        }
    }

    func read(_ key: String) throws -> String? {
        var query = baseQuery(key)
        query[kSecReturnData as String] = kCFBooleanTrue
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        switch status {
        case errSecSuccess:
            guard let data = item as? Data, let value = String(data: data, encoding: .utf8) else {
                throw KeychainError.dataConversionFailure
            }
            return value
        case errSecItemNotFound:
            return nil
        default:
            throw KeychainError.unexpectedStatus(status)
        }
    }

    func delete(_ key: String) throws {
        let status = SecItemDelete(baseQuery(key) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(status)
        }
    }
}
