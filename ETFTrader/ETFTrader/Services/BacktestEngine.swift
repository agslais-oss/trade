import Foundation

enum BacktestStrategy: String, CaseIterable, Identifiable {
    case smaCrossover = "SMA Crossover"
    case rsiMeanReversion = "RSI Mean Reversion"
    case buyAndHold = "Buy & Hold"
    var id: String { rawValue }
}

struct BacktestParameters {
    var strategy: BacktestStrategy = .smaCrossover
    var initialCapital: Double = 10_000
    var fastPeriod: Int = 20
    var slowPeriod: Int = 50
    var rsiPeriod: Int = 14
    var rsiOversold: Double = 30
    var rsiOverbought: Double = 70
}

/// Pure, deterministic backtester. Runs entirely on-device against historical
/// bars; never touches the broker. Used to evaluate a strategy before the user
/// approves any live order through the trade approval flow.
final class BacktestEngine {
    func run(symbol: String, bars: [Bar], params: BacktestParameters) -> BacktestResult {
        guard !bars.isEmpty else {
            return BacktestResult(
                symbol: symbol,
                strategy: params.strategy.rawValue,
                initialCapital: params.initialCapital,
                finalEquity: params.initialCapital,
                trades: [],
                equityCurve: [],
                maxDrawdown: 0,
                winRate: 0
            )
        }
        switch params.strategy {
        case .smaCrossover: return smaCrossover(symbol: symbol, bars: bars, params: params)
        case .rsiMeanReversion: return rsiMeanReversion(symbol: symbol, bars: bars, params: params)
        case .buyAndHold: return buyAndHold(symbol: symbol, bars: bars, params: params)
        }
    }

    private func smaCrossover(symbol: String, bars: [Bar], params: BacktestParameters) -> BacktestResult {
        let fastSMA = sma(bars.map(\.close), period: params.fastPeriod)
        let slowSMA = sma(bars.map(\.close), period: params.slowPeriod)
        var signals: [Int] = Array(repeating: 0, count: bars.count)
        for i in 1..<bars.count {
            guard let fNow = fastSMA[i], let sNow = slowSMA[i],
                  let fPrev = fastSMA[i - 1], let sPrev = slowSMA[i - 1] else { continue }
            if fPrev <= sPrev && fNow > sNow { signals[i] = 1 }
            else if fPrev >= sPrev && fNow < sNow { signals[i] = -1 }
        }
        return simulate(symbol: symbol, bars: bars, signals: signals, params: params)
    }

    private func rsiMeanReversion(symbol: String, bars: [Bar], params: BacktestParameters) -> BacktestResult {
        let rsiValues = rsi(bars.map(\.close), period: params.rsiPeriod)
        var signals: [Int] = Array(repeating: 0, count: bars.count)
        var holding = false
        for i in 0..<bars.count {
            guard let r = rsiValues[i] else { continue }
            if !holding && r < params.rsiOversold { signals[i] = 1; holding = true }
            else if holding && r > params.rsiOverbought { signals[i] = -1; holding = false }
        }
        return simulate(symbol: symbol, bars: bars, signals: signals, params: params)
    }

    private func buyAndHold(symbol: String, bars: [Bar], params: BacktestParameters) -> BacktestResult {
        var signals: [Int] = Array(repeating: 0, count: bars.count)
        signals[0] = 1
        signals[bars.count - 1] = -1
        return simulate(symbol: symbol, bars: bars, signals: signals, params: params)
    }

    private func simulate(
        symbol: String,
        bars: [Bar],
        signals: [Int],
        params: BacktestParameters
    ) -> BacktestResult {
        var cash = params.initialCapital
        var qty: Double = 0
        var entryPrice: Double = 0
        var trades: [BacktestTrade] = []
        var curve: [EquityPoint] = []

        for (i, bar) in bars.enumerated() {
            switch signals[i] {
            case 1 where qty == 0:
                let useCash = cash
                qty = floor(useCash / bar.close)
                if qty > 0 {
                    cash -= qty * bar.close
                    entryPrice = bar.close
                    trades.append(BacktestTrade(date: bar.timestamp, side: .buy, price: bar.close, qty: qty))
                }
            case -1 where qty > 0:
                let proceeds = qty * bar.close
                let pnl = (bar.close - entryPrice) * qty
                cash += proceeds
                trades.append(BacktestTrade(date: bar.timestamp, side: .sell, price: bar.close, qty: qty, pnl: pnl))
                qty = 0
                entryPrice = 0
            default:
                break
            }
            let equity = cash + qty * bar.close
            curve.append(EquityPoint(date: bar.timestamp, value: equity))
        }

        if qty > 0, let last = bars.last {
            let pnl = (last.close - entryPrice) * qty
            cash += qty * last.close
            trades.append(BacktestTrade(date: last.timestamp, side: .sell, price: last.close, qty: qty, pnl: pnl))
            qty = 0
        }

        let final = cash
        let dd = maxDrawdown(curve.map(\.value))
        let closed = trades.filter { $0.side == .sell }
        let wins = closed.filter { $0.pnl > 0 }.count
        let winRate = closed.isEmpty ? 0 : Double(wins) / Double(closed.count)

        return BacktestResult(
            symbol: symbol,
            strategy: params.strategy.rawValue,
            initialCapital: params.initialCapital,
            finalEquity: final,
            trades: trades,
            equityCurve: curve,
            maxDrawdown: dd,
            winRate: winRate
        )
    }

    func sma(_ values: [Double], period: Int) -> [Double?] {
        guard period > 0 else { return values.map { _ in nil } }
        var out: [Double?] = Array(repeating: nil, count: values.count)
        guard values.count >= period else { return out }
        var sum = values[0..<period].reduce(0, +)
        out[period - 1] = sum / Double(period)
        for i in period..<values.count {
            sum += values[i] - values[i - period]
            out[i] = sum / Double(period)
        }
        return out
    }

    func rsi(_ values: [Double], period: Int) -> [Double?] {
        guard values.count > period, period > 0 else {
            return Array(repeating: nil, count: values.count)
        }
        var out: [Double?] = Array(repeating: nil, count: values.count)
        var gains: Double = 0
        var losses: Double = 0
        for i in 1...period {
            let change = values[i] - values[i - 1]
            if change >= 0 { gains += change } else { losses -= change }
        }
        var avgGain = gains / Double(period)
        var avgLoss = losses / Double(period)
        out[period] = computeRSI(avgGain, avgLoss)
        for i in (period + 1)..<values.count {
            let change = values[i] - values[i - 1]
            let gain = max(change, 0)
            let loss = max(-change, 0)
            avgGain = (avgGain * Double(period - 1) + gain) / Double(period)
            avgLoss = (avgLoss * Double(period - 1) + loss) / Double(period)
            out[i] = computeRSI(avgGain, avgLoss)
        }
        return out
    }

    private func computeRSI(_ avgGain: Double, _ avgLoss: Double) -> Double {
        guard avgLoss > 0 else { return 100 }
        let rs = avgGain / avgLoss
        return 100 - (100 / (1 + rs))
    }

    func maxDrawdown(_ equity: [Double]) -> Double {
        var peak = -Double.infinity
        var maxDD: Double = 0
        for v in equity {
            peak = max(peak, v)
            if peak > 0 {
                maxDD = max(maxDD, (peak - v) / peak)
            }
        }
        return maxDD * 100
    }
}
