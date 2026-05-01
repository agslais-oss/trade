import Foundation

struct Account: Decodable, Equatable {
    let id: String
    let accountNumber: String
    let status: String
    let currency: String
    let cash: String
    let portfolioValue: String
    let buyingPower: String
    let equity: String
    let patternDayTrader: Bool
    let tradingBlocked: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case accountNumber = "account_number"
        case status
        case currency
        case cash
        case portfolioValue = "portfolio_value"
        case buyingPower = "buying_power"
        case equity
        case patternDayTrader = "pattern_day_trader"
        case tradingBlocked = "trading_blocked"
    }

    var cashValue: Double { Double(cash) ?? 0 }
    var equityValue: Double { Double(equity) ?? 0 }
    var buyingPowerValue: Double { Double(buyingPower) ?? 0 }
}
