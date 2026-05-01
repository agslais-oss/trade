import Foundation

enum OrderSide: String, Codable, CaseIterable, Identifiable {
    case buy
    case sell
    var id: String { rawValue }
}

enum OrderType: String, Codable, CaseIterable, Identifiable {
    case market
    case limit
    var id: String { rawValue }
}

enum TimeInForce: String, Codable, CaseIterable, Identifiable {
    case day
    case gtc
    var id: String { rawValue }
}

struct OrderRequest: Codable, Equatable {
    let symbol: String
    let qty: String
    let side: OrderSide
    let type: OrderType
    let timeInForce: TimeInForce
    let limitPrice: String?

    enum CodingKeys: String, CodingKey {
        case symbol, qty, side, type
        case timeInForce = "time_in_force"
        case limitPrice = "limit_price"
    }
}

struct Order: Decodable, Identifiable, Equatable {
    let id: String
    let clientOrderId: String?
    let symbol: String
    let qty: String?
    let filledQty: String?
    let side: String
    let type: String
    let timeInForce: String
    let status: String
    let submittedAt: String?
    let filledAvgPrice: String?
    let limitPrice: String?

    enum CodingKeys: String, CodingKey {
        case id
        case clientOrderId = "client_order_id"
        case symbol, qty
        case filledQty = "filled_qty"
        case side, type
        case timeInForce = "time_in_force"
        case status
        case submittedAt = "submitted_at"
        case filledAvgPrice = "filled_avg_price"
        case limitPrice = "limit_price"
    }
}
