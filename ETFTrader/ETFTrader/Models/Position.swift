import Foundation

struct Position: Decodable, Identifiable, Equatable {
    var id: String { symbol }
    let symbol: String
    let qty: String
    let avgEntryPrice: String
    let marketValue: String
    let costBasis: String
    let unrealizedPL: String
    let unrealizedPLPC: String
    let currentPrice: String?
    let side: String

    enum CodingKeys: String, CodingKey {
        case symbol, qty
        case avgEntryPrice = "avg_entry_price"
        case marketValue = "market_value"
        case costBasis = "cost_basis"
        case unrealizedPL = "unrealized_pl"
        case unrealizedPLPC = "unrealized_plpc"
        case currentPrice = "current_price"
        case side
    }

    var qtyValue: Double { Double(qty) ?? 0 }
    var marketValueValue: Double { Double(marketValue) ?? 0 }
    var unrealizedPLValue: Double { Double(unrealizedPL) ?? 0 }
    var unrealizedPLPercent: Double { (Double(unrealizedPLPC) ?? 0) * 100 }
}
