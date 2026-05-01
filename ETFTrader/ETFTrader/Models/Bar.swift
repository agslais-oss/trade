import Foundation

struct Bar: Decodable, Equatable {
    let timestamp: Date
    let open: Double
    let high: Double
    let low: Double
    let close: Double
    let volume: Double

    enum CodingKeys: String, CodingKey {
        case timestamp = "t"
        case open = "o"
        case high = "h"
        case low = "l"
        case close = "c"
        case volume = "v"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let ts = try c.decode(String.self, forKey: .timestamp)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        self.timestamp = formatter.date(from: ts)
            ?? ISO8601DateFormatter().date(from: ts)
            ?? Date()
        self.open = try c.decode(Double.self, forKey: .open)
        self.high = try c.decode(Double.self, forKey: .high)
        self.low = try c.decode(Double.self, forKey: .low)
        self.close = try c.decode(Double.self, forKey: .close)
        self.volume = try c.decode(Double.self, forKey: .volume)
    }

    init(timestamp: Date, open: Double, high: Double, low: Double, close: Double, volume: Double) {
        self.timestamp = timestamp
        self.open = open
        self.high = high
        self.low = low
        self.close = close
        self.volume = volume
    }
}

struct BarsResponse: Decodable {
    let bars: [Bar]
    let nextPageToken: String?

    enum CodingKeys: String, CodingKey {
        case bars
        case nextPageToken = "next_page_token"
    }
}
