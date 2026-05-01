import XCTest
@testable import ETFTrader

final class BacktestEngineTests: XCTestCase {
    private let engine = BacktestEngine()

    func testSMAComputesCorrectAverages() {
        let values: [Double] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
        let result = engine.sma(values, period: 3)
        XCTAssertNil(result[0])
        XCTAssertNil(result[1])
        XCTAssertEqual(result[2], 2.0, accuracy: 1e-9)
        XCTAssertEqual(result[5], 5.0, accuracy: 1e-9)
        XCTAssertEqual(result[9], 9.0, accuracy: 1e-9)
    }

    func testRSIBoundsAreReasonable() {
        let upTrend = (1...30).map { Double($0) }
        let rsi = engine.rsi(upTrend, period: 14)
        XCTAssertNotNil(rsi.last!)
        XCTAssertGreaterThan(rsi.last!!, 90)
    }

    func testMaxDrawdownDetectsPeakToTrough() {
        let curve: [Double] = [100, 110, 120, 90, 80, 130]
        let dd = engine.maxDrawdown(curve)
        XCTAssertEqual(dd, (120.0 - 80.0) / 120.0 * 100.0, accuracy: 1e-9)
    }

    func testBuyAndHoldEarnsFullPriceReturn() {
        let bars = makeBars(prices: [100, 110, 120, 130, 140])
        let params = BacktestParameters(strategy: .buyAndHold, initialCapital: 1000)
        let result = engine.run(symbol: "SPY", bars: bars, params: params)
        XCTAssertGreaterThan(result.finalEquity, params.initialCapital)
        XCTAssertEqual(result.trades.count, 2)
    }

    func testSMACrossoverProducesAtLeastOneTrade() {
        let prices: [Double] = (0..<60).map { i in
            i < 30 ? 100 - Double(i) * 0.5 : 85 + Double(i - 30) * 1.0
        }
        let bars = makeBars(prices: prices)
        let params = BacktestParameters(
            strategy: .smaCrossover,
            initialCapital: 5000,
            fastPeriod: 5,
            slowPeriod: 20
        )
        let result = engine.run(symbol: "SPY", bars: bars, params: params)
        XCTAssertGreaterThan(result.trades.count, 0)
    }

    private func makeBars(prices: [Double]) -> [Bar] {
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        return prices.enumerated().map { i, p in
            Bar(
                timestamp: start.addingTimeInterval(Double(i) * 86400),
                open: p, high: p, low: p, close: p, volume: 1
            )
        }
    }
}
