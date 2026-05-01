import Foundation

struct BacktestTrade: Identifiable, Equatable {
    let id = UUID()
    let date: Date
    let side: OrderSide
    let price: Double
    let qty: Double
    var pnl: Double = 0
}

struct EquityPoint: Identifiable, Equatable {
    let id = UUID()
    let date: Date
    let value: Double
}

struct BacktestResult: Equatable {
    let symbol: String
    let strategy: String
    let initialCapital: Double
    let finalEquity: Double
    let trades: [BacktestTrade]
    let equityCurve: [EquityPoint]
    let maxDrawdown: Double
    let winRate: Double

    var totalReturnPercent: Double {
        guard initialCapital > 0 else { return 0 }
        return ((finalEquity - initialCapital) / initialCapital) * 100
    }

    var totalPnL: Double { finalEquity - initialCapital }
}
