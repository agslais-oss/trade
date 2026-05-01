import Foundation

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var apiKeyId: String = ""
    @Published var apiSecret: String = ""
    @Published var statusMessage: String?
    @Published var isConfigured: Bool = false

    private let keychain: KeychainServicing

    init(keychain: KeychainServicing = KeychainService.shared) {
        self.keychain = keychain
        load()
    }

    func load() {
        do {
            apiKeyId = (try keychain.read(KeychainService.apiKeyIdentifier)) ?? ""
            apiSecret = (try keychain.read(KeychainService.apiSecretIdentifier)) ?? ""
            isConfigured = !apiKeyId.isEmpty && !apiSecret.isEmpty
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    func save() {
        let trimmedKey = apiKeyId.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedSecret = apiSecret.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty, !trimmedSecret.isEmpty else {
            statusMessage = "Both fields are required."
            return
        }
        do {
            try keychain.save(trimmedKey, for: KeychainService.apiKeyIdentifier)
            try keychain.save(trimmedSecret, for: KeychainService.apiSecretIdentifier)
            isConfigured = true
            statusMessage = "Saved to Keychain."
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    func clear() {
        do {
            try keychain.delete(KeychainService.apiKeyIdentifier)
            try keychain.delete(KeychainService.apiSecretIdentifier)
            apiKeyId = ""
            apiSecret = ""
            isConfigured = false
            statusMessage = "Credentials cleared."
        } catch {
            statusMessage = error.localizedDescription
        }
    }
}
