import XCTest
@testable import ETFTrader

private final class MockAlpacaAPI: AlpacaAPIProtocol {
    var asset: Asset
    var placedOrders: [OrderRequest] = []
    var nextOrder: Order

    init(asset: Asset, nextOrder: Order) {
        self.asset = asset
        self.nextOrder = nextOrder
    }

    func getAccount() async throws -> Account {
        Account(
            id: "a", accountNumber: "n", status: "ACTIVE", currency: "USD",
            cash: "100", portfolioValue: "100", buyingPower: "100", equity: "100",
            patternDayTrader: false, tradingBlocked: false
        )
    }
    func getPositions() async throws -> [Position] { [] }
    func getOrders(status: String) async throws -> [Order] { [] }
    func getAsset(symbol: String) async throws -> Asset { asset }
    func placeOrder(_ request: OrderRequest) async throws -> Order {
        placedOrders.append(request)
        return nextOrder
    }
    func cancelOrder(id: String) async throws {}
    func getBars(symbol: String, timeframe: String, start: Date, end: Date) async throws -> [Bar] { [] }
}

@MainActor
final class TradeViewModelTests: XCTestCase {
    private func makeOrder() -> Order {
        Order(
            id: "1", clientOrderId: nil, symbol: "SPY", qty: "1", filledQty: "0",
            side: "buy", type: "market", timeInForce: "day", status: "accepted",
            submittedAt: nil, filledAvgPrice: nil, limitPrice: nil
        )
    }

    func testRejectsNonETFSymbol() async {
        let asset = Asset(
            id: "1", symbol: "AAPL", name: "Apple Inc.", assetClass: "us_equity",
            exchange: "NASDAQ", tradable: true, attributes: []
        )
        let api = MockAlpacaAPI(asset: asset, nextOrder: makeOrder())
        let vm = TradeViewModel(api: api)
        vm.symbol = "AAPL"
        await vm.prepareForApproval()
        XCTAssertFalse(vm.pendingApproval)
        XCTAssertNotNil(vm.errorMessage)
        XCTAssertTrue(api.placedOrders.isEmpty)
    }

    func testApprovalFlowDoesNotSubmitWithoutConfirmation() async {
        let asset = Asset(
            id: "1", symbol: "SPY", name: "SPDR S&P 500 ETF", assetClass: "us_equity",
            exchange: "ARCA", tradable: true, attributes: ["etp"]
        )
        let api = MockAlpacaAPI(asset: asset, nextOrder: makeOrder())
        let vm = TradeViewModel(api: api)
        vm.symbol = "SPY"
        await vm.prepareForApproval()
        XCTAssertTrue(vm.pendingApproval)
        XCTAssertEqual(api.placedOrders.count, 0,
                       "Preparing for approval must not place any order.")
    }

    func testConfirmAndSubmitPlacesOrderOnlyAfterApproval() async {
        let asset = Asset(
            id: "1", symbol: "SPY", name: "SPDR S&P 500 ETF", assetClass: "us_equity",
            exchange: "ARCA", tradable: true, attributes: ["etp"]
        )
        let api = MockAlpacaAPI(asset: asset, nextOrder: makeOrder())
        let vm = TradeViewModel(api: api)
        vm.symbol = "SPY"

        // Without prepareForApproval, confirmAndSubmit must do nothing.
        await vm.confirmAndSubmit()
        XCTAssertEqual(api.placedOrders.count, 0)

        await vm.prepareForApproval()
        XCTAssertTrue(vm.pendingApproval)

        await vm.confirmAndSubmit()
        XCTAssertEqual(api.placedOrders.count, 1)
        XCTAssertFalse(vm.pendingApproval)
        XCTAssertNotNil(vm.lastOrder)
    }
}
