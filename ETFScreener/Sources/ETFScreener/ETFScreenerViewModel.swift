import Foundation

public enum ETFSortKey: String, CaseIterable, Identifiable, Sendable {
    case changePercent = "% Change"
    case volume = "Volume"
    case price = "Price"
    case symbol = "Symbol"

    public var id: Self { self }
}

struct ETFRow: Identifiable, Equatable {
    let etf: ETF
    let quote: ETFQuote?

    var id: String { etf.symbol }
}

@MainActor
final class ETFScreenerViewModel: ObservableObject {
    @Published private(set) var quotes: [String: ETFQuote] = [:]
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var lastUpdated: Date?

    @Published var category: ETFCategory?
    @Published var searchText = ""
    @Published var sortKey: ETFSortKey = .changePercent
    @Published var ascending = false

    let universe: [ETF]
    private let client: AlpacaMarketDataClient

    init(client: AlpacaMarketDataClient, universe: [ETF]) {
        self.client = client
        self.universe = universe
    }

    var availableCategories: [ETFCategory] {
        let present = Set(universe.map(\.category))
        return ETFCategory.allCases.filter(present.contains)
    }

    var rows: [ETFRow] {
        let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        let filtered = universe.filter { etf in
            (category == nil || etf.category == category)
                && (query.isEmpty
                    || etf.symbol.lowercased().contains(query)
                    || etf.name.lowercased().contains(query))
        }
        return filtered
            .map { ETFRow(etf: $0, quote: quotes[$0.symbol]) }
            .sorted(by: areInOrder)
    }

    func refresh() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            quotes = try await client.quotes(for: universe.map(\.symbol))
            lastUpdated = Date()
            errorMessage = nil
        } catch is CancellationError {
            // View went away or a refresh was superseded; keep existing data.
        } catch let error as URLError where error.code == .cancelled {
            // Same as above, surfaced by URLSession.
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func areInOrder(_ a: ETFRow, _ b: ETFRow) -> Bool {
        if sortKey == .symbol {
            return ascending ? a.etf.symbol < b.etf.symbol : a.etf.symbol > b.etf.symbol
        }
        let lhs = value(for: a), rhs = value(for: b)
        switch (lhs, rhs) {
        case let (l?, r?) where l != r:
            return ascending ? l < r : l > r
        case (nil, _?):
            return false // rows without data always sink to the bottom
        case (_?, nil):
            return true
        default:
            return a.etf.symbol < b.etf.symbol
        }
    }

    private func value(for row: ETFRow) -> Double? {
        switch sortKey {
        case .changePercent: return row.quote?.changePercent
        case .volume: return row.quote?.volume
        case .price: return row.quote?.price
        case .symbol: return nil
        }
    }
}
