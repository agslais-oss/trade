import Foundation

public enum ETFCategory: String, CaseIterable, Identifiable, Sendable {
    case broadMarket = "Broad Market"
    case international = "International"
    case sector = "Sector"
    case bonds = "Bonds"
    case commodities = "Commodities"
    case dividend = "Dividend"
    case thematic = "Thematic"
    case leveraged = "Leveraged"

    public var id: Self { self }
}

public struct ETF: Identifiable, Hashable, Sendable {
    public let symbol: String
    public let name: String
    public let category: ETFCategory

    public var id: String { symbol }

    public init(symbol: String, name: String, category: ETFCategory) {
        self.symbol = symbol
        self.name = name
        self.category = category
    }
}

public extension ETF {
    /// A curated list of widely traded US-listed ETFs. Alpaca's asset API does not
    /// flag which equities are ETFs, so the screener works from an explicit universe.
    /// Pass your own list to `ETFScreenerView(universe:)` to customise it.
    static let defaultUniverse: [ETF] = [
        // Broad market
        ETF(symbol: "SPY", name: "SPDR S&P 500 ETF Trust", category: .broadMarket),
        ETF(symbol: "VOO", name: "Vanguard S&P 500 ETF", category: .broadMarket),
        ETF(symbol: "IVV", name: "iShares Core S&P 500 ETF", category: .broadMarket),
        ETF(symbol: "VTI", name: "Vanguard Total Stock Market ETF", category: .broadMarket),
        ETF(symbol: "QQQ", name: "Invesco QQQ Trust", category: .broadMarket),
        ETF(symbol: "DIA", name: "SPDR Dow Jones Industrial Average ETF", category: .broadMarket),
        ETF(symbol: "IWM", name: "iShares Russell 2000 ETF", category: .broadMarket),
        ETF(symbol: "IJH", name: "iShares Core S&P Mid-Cap ETF", category: .broadMarket),
        // International
        ETF(symbol: "VEA", name: "Vanguard FTSE Developed Markets ETF", category: .international),
        ETF(symbol: "IEFA", name: "iShares Core MSCI EAFE ETF", category: .international),
        ETF(symbol: "EFA", name: "iShares MSCI EAFE ETF", category: .international),
        ETF(symbol: "VWO", name: "Vanguard FTSE Emerging Markets ETF", category: .international),
        ETF(symbol: "EEM", name: "iShares MSCI Emerging Markets ETF", category: .international),
        // Sector
        ETF(symbol: "XLK", name: "Technology Select Sector SPDR", category: .sector),
        ETF(symbol: "XLF", name: "Financial Select Sector SPDR", category: .sector),
        ETF(symbol: "XLE", name: "Energy Select Sector SPDR", category: .sector),
        ETF(symbol: "XLV", name: "Health Care Select Sector SPDR", category: .sector),
        ETF(symbol: "XLY", name: "Consumer Discretionary Select Sector SPDR", category: .sector),
        ETF(symbol: "XLP", name: "Consumer Staples Select Sector SPDR", category: .sector),
        ETF(symbol: "XLI", name: "Industrial Select Sector SPDR", category: .sector),
        ETF(symbol: "XLU", name: "Utilities Select Sector SPDR", category: .sector),
        ETF(symbol: "XLB", name: "Materials Select Sector SPDR", category: .sector),
        ETF(symbol: "XLRE", name: "Real Estate Select Sector SPDR", category: .sector),
        ETF(symbol: "XLC", name: "Communication Services Select Sector SPDR", category: .sector),
        ETF(symbol: "SMH", name: "VanEck Semiconductor ETF", category: .sector),
        ETF(symbol: "VNQ", name: "Vanguard Real Estate ETF", category: .sector),
        // Bonds
        ETF(symbol: "AGG", name: "iShares Core U.S. Aggregate Bond ETF", category: .bonds),
        ETF(symbol: "BND", name: "Vanguard Total Bond Market ETF", category: .bonds),
        ETF(symbol: "TLT", name: "iShares 20+ Year Treasury Bond ETF", category: .bonds),
        ETF(symbol: "IEF", name: "iShares 7-10 Year Treasury Bond ETF", category: .bonds),
        ETF(symbol: "SHY", name: "iShares 1-3 Year Treasury Bond ETF", category: .bonds),
        ETF(symbol: "TIP", name: "iShares TIPS Bond ETF", category: .bonds),
        ETF(symbol: "LQD", name: "iShares iBoxx $ Investment Grade Corporate Bond ETF", category: .bonds),
        ETF(symbol: "HYG", name: "iShares iBoxx $ High Yield Corporate Bond ETF", category: .bonds),
        // Commodities
        ETF(symbol: "GLD", name: "SPDR Gold Shares", category: .commodities),
        ETF(symbol: "SLV", name: "iShares Silver Trust", category: .commodities),
        ETF(symbol: "USO", name: "United States Oil Fund", category: .commodities),
        ETF(symbol: "DBC", name: "Invesco DB Commodity Index Tracking Fund", category: .commodities),
        // Dividend
        ETF(symbol: "SCHD", name: "Schwab U.S. Dividend Equity ETF", category: .dividend),
        ETF(symbol: "VIG", name: "Vanguard Dividend Appreciation ETF", category: .dividend),
        ETF(symbol: "VYM", name: "Vanguard High Dividend Yield ETF", category: .dividend),
        // Thematic
        ETF(symbol: "ARKK", name: "ARK Innovation ETF", category: .thematic),
        ETF(symbol: "ICLN", name: "iShares Global Clean Energy ETF", category: .thematic),
        ETF(symbol: "BOTZ", name: "Global X Robotics & Artificial Intelligence ETF", category: .thematic),
        // Leveraged / inverse
        ETF(symbol: "TQQQ", name: "ProShares UltraPro QQQ (3x)", category: .leveraged),
        ETF(symbol: "SQQQ", name: "ProShares UltraPro Short QQQ (-3x)", category: .leveraged),
        ETF(symbol: "SPXL", name: "Direxion Daily S&P 500 Bull 3X", category: .leveraged),
        ETF(symbol: "SH", name: "ProShares Short S&P 500 (-1x)", category: .leveraged),
    ]
}
