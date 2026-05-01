import Foundation

struct Asset: Decodable, Identifiable, Hashable {
    let id: String
    let symbol: String
    let name: String
    let assetClass: String
    let exchange: String
    let tradable: Bool
    let attributes: [String]?

    enum CodingKeys: String, CodingKey {
        case id
        case symbol
        case name
        case assetClass = "class"
        case exchange
        case tradable
        case attributes
    }

    var isETF: Bool {
        let attrs = attributes ?? []
        if attrs.contains(where: { $0.lowercased() == "etp" || $0.lowercased() == "etf" }) {
            return true
        }
        return name.uppercased().contains("ETF")
            || ETFAllowlist.contains(symbol.uppercased())
    }
}

enum ETFAllowlist {
    static let symbols: Set<String> = [
        "SPY", "VOO", "IVV", "QQQ", "VTI", "IWM", "DIA", "EFA", "EEM", "AGG",
        "BND", "GLD", "SLV", "TLT", "HYG", "LQD", "VEA", "VWO", "VXUS", "VGK",
        "XLK", "XLF", "XLE", "XLV", "XLI", "XLY", "XLP", "XLU", "XLB", "XLRE",
        "ARKK", "SCHD", "VYM", "VIG", "VTV", "VUG", "MDY", "RSP", "QUAL", "MTUM"
    ]

    static func contains(_ symbol: String) -> Bool {
        symbols.contains(symbol.uppercased())
    }
}
