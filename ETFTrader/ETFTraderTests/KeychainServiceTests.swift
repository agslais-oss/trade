import XCTest
@testable import ETFTrader

/// In-memory fake exercising the same protocol the app uses, so the trade flow
/// can be tested without touching the device Keychain.
final class InMemoryKeychain: KeychainServicing {
    private var store: [String: String] = [:]
    func save(_ value: String, for key: String) throws { store[key] = value }
    func read(_ key: String) throws -> String? { store[key] }
    func delete(_ key: String) throws { store.removeValue(forKey: key) }
}

final class KeychainServiceTests: XCTestCase {
    func testSaveReadDeleteRoundTrip() throws {
        let kc = InMemoryKeychain()
        try kc.save("KEY", for: KeychainService.apiKeyIdentifier)
        try kc.save("SECRET", for: KeychainService.apiSecretIdentifier)
        XCTAssertEqual(try kc.read(KeychainService.apiKeyIdentifier), "KEY")
        XCTAssertEqual(try kc.read(KeychainService.apiSecretIdentifier), "SECRET")
        try kc.delete(KeychainService.apiKeyIdentifier)
        XCTAssertNil(try kc.read(KeychainService.apiKeyIdentifier))
    }
}
