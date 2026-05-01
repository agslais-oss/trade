import Foundation

@MainActor
final class AccountViewModel: ObservableObject {
    @Published private(set) var account: Account?
    @Published private(set) var positions: [Position] = []
    @Published private(set) var orders: [Order] = []
    @Published var errorMessage: String?
    @Published var isLoading = false

    private let api: AlpacaAPIProtocol

    init(api: AlpacaAPIProtocol = AlpacaAPI()) {
        self.api = api
    }

    func refresh() async {
        isLoading = true
        defer { isLoading = false }
        do {
            async let acct = api.getAccount()
            async let pos = api.getPositions()
            async let ord = api.getOrders(status: "all")
            self.account = try await acct
            self.positions = try await pos
            self.orders = try await ord
            self.errorMessage = nil
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    func cancelOrder(_ id: String) async {
        do {
            try await api.cancelOrder(id: id)
            await refresh()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
