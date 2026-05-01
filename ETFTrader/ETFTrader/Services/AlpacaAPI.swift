import Foundation

enum AlpacaError: Error, LocalizedError {
    case missingCredentials
    case invalidURL
    case http(status: Int, body: String)
    case decoding(Error)
    case notAnETF(symbol: String)
    case transport(Error)

    var errorDescription: String? {
        switch self {
        case .missingCredentials: return "Alpaca API credentials are not configured. Open Settings."
        case .invalidURL: return "Invalid request URL."
        case .http(let s, let body): return "HTTP \(s): \(body)"
        case .decoding(let e): return "Decoding failure: \(e.localizedDescription)"
        case .notAnETF(let s): return "\(s) is not an ETF. This app only trades ETFs."
        case .transport(let e): return "Network error: \(e.localizedDescription)"
        }
    }
}

enum AlpacaEnvironment {
    static let paperTradingBase = URL(string: "https://paper-api.alpaca.markets/v2")!
    static let marketDataBase = URL(string: "https://data.alpaca.markets/v2")!
}

protocol AlpacaAPIProtocol {
    func getAccount() async throws -> Account
    func getPositions() async throws -> [Position]
    func getOrders(status: String) async throws -> [Order]
    func getAsset(symbol: String) async throws -> Asset
    func placeOrder(_ request: OrderRequest) async throws -> Order
    func cancelOrder(id: String) async throws
    func getBars(symbol: String, timeframe: String, start: Date, end: Date) async throws -> [Bar]
}

/// Thin REST client for Alpaca's paper-trading endpoints.
///
/// All order placement is gated by `placeOrder` which refuses any symbol that
/// is not classified as an ETF on the Alpaca asset record. The UI also gates
/// orders behind an explicit user confirmation screen — this is a
/// belt-and-suspenders second guard.
final class AlpacaAPI: AlpacaAPIProtocol {
    private let session: URLSession
    private let keychain: KeychainServicing
    private let tradingBase: URL
    private let dataBase: URL
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(
        session: URLSession = .shared,
        keychain: KeychainServicing = KeychainService.shared,
        tradingBase: URL = AlpacaEnvironment.paperTradingBase,
        dataBase: URL = AlpacaEnvironment.marketDataBase
    ) {
        self.session = session
        self.keychain = keychain
        self.tradingBase = tradingBase
        self.dataBase = dataBase
        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()
    }

    private func authHeaders() throws -> [String: String] {
        guard
            let key = try keychain.read(KeychainService.apiKeyIdentifier),
            let secret = try keychain.read(KeychainService.apiSecretIdentifier),
            !key.isEmpty, !secret.isEmpty
        else {
            throw AlpacaError.missingCredentials
        }
        return [
            "APCA-API-KEY-ID": key,
            "APCA-API-SECRET-KEY": secret,
            "Content-Type": "application/json",
            "Accept": "application/json"
        ]
    }

    private func request<T: Decodable>(
        _ method: String,
        url: URL,
        body: Data? = nil
    ) async throws -> T {
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.httpBody = body
        for (k, v) in try authHeaders() { req.setValue(v, forHTTPHeaderField: k) }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: req)
        } catch {
            throw AlpacaError.transport(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw AlpacaError.http(status: -1, body: "no response")
        }
        guard (200..<300).contains(http.statusCode) else {
            throw AlpacaError.http(status: http.statusCode, body: String(data: data, encoding: .utf8) ?? "")
        }
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw AlpacaError.decoding(error)
        }
    }

    private func requestVoid(_ method: String, url: URL) async throws {
        var req = URLRequest(url: url)
        req.httpMethod = method
        for (k, v) in try authHeaders() { req.setValue(v, forHTTPHeaderField: k) }
        let (data, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw AlpacaError.http(status: code, body: String(data: data, encoding: .utf8) ?? "")
        }
    }

    func getAccount() async throws -> Account {
        try await request("GET", url: tradingBase.appendingPathComponent("account"))
    }

    func getPositions() async throws -> [Position] {
        try await request("GET", url: tradingBase.appendingPathComponent("positions"))
    }

    func getOrders(status: String = "all") async throws -> [Order] {
        var components = URLComponents(
            url: tradingBase.appendingPathComponent("orders"),
            resolvingAgainstBaseURL: false
        )!
        components.queryItems = [
            URLQueryItem(name: "status", value: status),
            URLQueryItem(name: "limit", value: "50"),
            URLQueryItem(name: "direction", value: "desc")
        ]
        return try await request("GET", url: components.url!)
    }

    func getAsset(symbol: String) async throws -> Asset {
        try await request(
            "GET",
            url: tradingBase.appendingPathComponent("assets/\(symbol.uppercased())")
        )
    }

    func placeOrder(_ request: OrderRequest) async throws -> Order {
        let asset = try await getAsset(symbol: request.symbol)
        guard asset.tradable else {
            throw AlpacaError.http(status: 400, body: "\(asset.symbol) is not tradable")
        }
        guard asset.isETF else {
            throw AlpacaError.notAnETF(symbol: asset.symbol)
        }
        let body = try encoder.encode(request)
        return try await self.request(
            "POST",
            url: tradingBase.appendingPathComponent("orders"),
            body: body
        )
    }

    func cancelOrder(id: String) async throws {
        try await requestVoid(
            "DELETE",
            url: tradingBase.appendingPathComponent("orders/\(id)")
        )
    }

    func getBars(
        symbol: String,
        timeframe: String = "1Day",
        start: Date,
        end: Date
    ) async throws -> [Bar] {
        var components = URLComponents(
            url: dataBase.appendingPathComponent("stocks/\(symbol.uppercased())/bars"),
            resolvingAgainstBaseURL: false
        )!
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime]
        components.queryItems = [
            URLQueryItem(name: "timeframe", value: timeframe),
            URLQueryItem(name: "start", value: iso.string(from: start)),
            URLQueryItem(name: "end", value: iso.string(from: end)),
            URLQueryItem(name: "limit", value: "10000"),
            URLQueryItem(name: "adjustment", value: "all")
        ]
        let response: BarsResponse = try await request("GET", url: components.url!)
        return response.bars
    }
}
