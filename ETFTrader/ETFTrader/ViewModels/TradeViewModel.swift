import Foundation

@MainActor
final class TradeViewModel: ObservableObject {
    @Published var symbol: String = "SPY"
    @Published var qty: String = "1"
    @Published var side: OrderSide = .buy
    @Published var orderType: OrderType = .market
    @Published var timeInForce: TimeInForce = .day
    @Published var limitPrice: String = ""

    @Published var validatedAsset: Asset?
    @Published var pendingApproval = false
    @Published var lastOrder: Order?
    @Published var errorMessage: String?
    @Published var isWorking = false

    private let api: AlpacaAPIProtocol

    init(api: AlpacaAPIProtocol = AlpacaAPI()) {
        self.api = api
    }

    func buildRequest() -> OrderRequest? {
        let trimSymbol = symbol.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let trimQty = qty.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimSymbol.isEmpty,
              let qtyValue = Double(trimQty), qtyValue > 0 else {
            errorMessage = "Enter a valid symbol and quantity."
            return nil
        }
        var price: String?
        if orderType == .limit {
            let trimPrice = limitPrice.trimmingCharacters(in: .whitespacesAndNewlines)
            guard let p = Double(trimPrice), p > 0 else {
                errorMessage = "Enter a valid limit price."
                return nil
            }
            price = String(p)
        }
        return OrderRequest(
            symbol: trimSymbol,
            qty: trimQty,
            side: side,
            type: orderType,
            timeInForce: timeInForce,
            limitPrice: price
        )
    }

    /// Validates the symbol is an ETF and stages the order for user approval.
    /// Calling this does NOT submit any order — it only opens the approval
    /// sheet. The order is submitted only by `confirmAndSubmit()`.
    func prepareForApproval() async {
        errorMessage = nil
        guard let request = buildRequest() else { return }
        isWorking = true
        defer { isWorking = false }
        do {
            let asset = try await api.getAsset(symbol: request.symbol)
            guard asset.tradable else {
                errorMessage = "\(asset.symbol) is not tradable."
                return
            }
            guard asset.isETF else {
                errorMessage = "\(asset.symbol) is not an ETF. ETFTrader only trades ETFs."
                return
            }
            self.validatedAsset = asset
            self.pendingApproval = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// User has explicitly confirmed the order in the approval screen.
    func confirmAndSubmit() async {
        guard pendingApproval, let request = buildRequest() else {
            errorMessage = "Order is not approved."
            return
        }
        isWorking = true
        defer { isWorking = false }
        do {
            let order = try await api.placeOrder(request)
            self.lastOrder = order
            self.pendingApproval = false
            self.validatedAsset = nil
            self.errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func cancelApproval() {
        pendingApproval = false
        validatedAsset = nil
    }
}
