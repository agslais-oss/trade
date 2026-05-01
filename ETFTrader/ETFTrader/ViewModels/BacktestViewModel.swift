import Foundation

@MainActor
final class BacktestViewModel: ObservableObject {
    @Published var symbol: String = "SPY"
    @Published var lookbackDays: Int = 365
    @Published var params = BacktestParameters()
    @Published var result: BacktestResult?
    @Published var errorMessage: String?
    @Published var isRunning = false

    private let api: AlpacaAPIProtocol
    private let engine: BacktestEngine

    init(api: AlpacaAPIProtocol = AlpacaAPI(), engine: BacktestEngine = BacktestEngine()) {
        self.api = api
        self.engine = engine
    }

    func run() async {
        errorMessage = nil
        let trimmed = symbol.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !trimmed.isEmpty else {
            errorMessage = "Enter a symbol."
            return
        }
        isRunning = true
        defer { isRunning = false }
        do {
            let asset = try await api.getAsset(symbol: trimmed)
            guard asset.isETF else {
                errorMessage = "\(asset.symbol) is not an ETF. ETFTrader only backtests ETFs."
                return
            }
            let end = Date()
            let start = Calendar.current.date(byAdding: .day, value: -lookbackDays, to: end) ?? end
            let bars = try await api.getBars(
                symbol: trimmed,
                timeframe: "1Day",
                start: start,
                end: end
            )
            guard bars.count > params.slowPeriod else {
                errorMessage = "Not enough historical data for the selected strategy."
                return
            }
            self.result = engine.run(symbol: trimmed, bars: bars, params: params)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
