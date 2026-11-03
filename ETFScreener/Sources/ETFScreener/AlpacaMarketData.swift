import Foundation

/// Which Alpaca market-data feed to query. Free (Basic) plans only have `iex`;
/// `sip` needs an Algo Trader Plus subscription.
public enum AlpacaDataFeed: String, Sendable {
    case iex
    case sip
}

public struct ETFQuote: Equatable, Sendable {
    public let price: Double
    public let previousClose: Double?
    public let volume: Double?

    public var change: Double? {
        previousClose.map { price - $0 }
    }

    public var changePercent: Double? {
        guard let previousClose, previousClose != 0 else { return nil }
        return (price - previousClose) / previousClose
    }
}

enum AlpacaError: LocalizedError {
    case invalidResponse
    case http(status: Int, message: String?)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Alpaca returned an unexpected response."
        case let .http(status, message) where status == 401 || status == 403:
            return "Alpaca rejected the API key (\(status)). Check the key ID and secret."
                + (message.map { " \($0)" } ?? "")
        case let .http(status, message):
            return "Alpaca request failed (\(status))." + (message.map { " \($0)" } ?? "")
        }
    }
}

struct AlpacaMarketDataClient: Sendable {
    let keyID: String
    let secret: String
    var feed: AlpacaDataFeed = .iex
    var session: URLSession = .shared

    private static let baseURL = URL(string: "https://data.alpaca.markets/v2")!

    /// GET /v2/stocks/snapshots — latest trade plus today's and the previous daily bar.
    func quotes(for symbols: [String]) async throws -> [String: ETFQuote] {
        guard !symbols.isEmpty else { return [:] }

        var components = URLComponents(
            url: Self.baseURL.appendingPathComponent("stocks/snapshots"),
            resolvingAgainstBaseURL: false
        )!
        components.queryItems = [
            URLQueryItem(name: "symbols", value: symbols.joined(separator: ",")),
            URLQueryItem(name: "feed", value: feed.rawValue),
        ]

        var request = URLRequest(url: components.url!)
        request.setValue(keyID, forHTTPHeaderField: "APCA-API-KEY-ID")
        request.setValue(secret, forHTTPHeaderField: "APCA-API-SECRET-KEY")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw AlpacaError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else {
            let message = (try? JSONDecoder().decode(ErrorBody.self, from: data))?.message
            throw AlpacaError.http(status: http.statusCode, message: message)
        }

        // Symbols without data come back as `null`.
        let snapshots = try JSONDecoder().decode([String: Snapshot?].self, from: data)
        return snapshots.compactMapValues { snapshot in
            guard let snapshot,
                  let price = snapshot.latestTrade?.p ?? snapshot.dailyBar?.c
            else { return nil }
            return ETFQuote(
                price: price,
                previousClose: snapshot.prevDailyBar?.c,
                volume: snapshot.dailyBar?.v
            )
        }
    }

    private struct Snapshot: Decodable {
        let latestTrade: Trade?
        let dailyBar: Bar?
        let prevDailyBar: Bar?

        struct Trade: Decodable { let p: Double }
        struct Bar: Decodable { let c: Double; let v: Double }
    }

    private struct ErrorBody: Decodable { let message: String? }
}
