import SwiftUI

/// A live ETF screener backed by Alpaca market data.
///
/// ```swift
/// NavigationView {
///     ETFScreenerView(keyID: keyID, secret: secret) { symbol in
///         selectedSymbol = symbol
///     }
/// }
/// ```
///
/// The view sets its own navigation title, toolbar and search field, so embed it in a
/// `NavigationView` / `NavigationStack`. The closure is called with the tapped ETF's symbol.
public struct ETFScreenerView: View {
    @StateObject private var model: ETFScreenerViewModel
    private let refreshInterval: TimeInterval?
    private let onSelect: (String) -> Void

    /// - Parameters:
    ///   - keyID: Alpaca API key ID (paper or live keys both work for market data).
    ///   - secret: Alpaca API secret key.
    ///   - feed: Market-data feed. `.iex` works on Alpaca's free plan.
    ///   - universe: The ETFs to screen. Defaults to a curated list of liquid US ETFs.
    ///   - refreshInterval: Seconds between automatic refreshes while visible; `nil` disables.
    ///   - onSelect: Called with the symbol of the ETF the user taps.
    public init(
        keyID: String,
        secret: String,
        feed: AlpacaDataFeed = .iex,
        universe: [ETF] = ETF.defaultUniverse,
        refreshInterval: TimeInterval? = 60,
        onSelect: @escaping (String) -> Void
    ) {
        let client = AlpacaMarketDataClient(keyID: keyID, secret: secret, feed: feed)
        _model = StateObject(wrappedValue: ETFScreenerViewModel(client: client, universe: universe))
        self.refreshInterval = refreshInterval
        self.onSelect = onSelect
    }

    public var body: some View {
        List {
            if let error = model.errorMessage {
                Section {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                        .font(.callout)
                }
            }

            Section {
                CategoryChips(categories: model.availableCategories, selection: $model.category)
                    .listRowInsets(EdgeInsets())
            }

            Section(footer: footer) {
                let rows = model.rows
                if rows.isEmpty {
                    Text("No ETFs match your filters.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(rows) { row in
                        Button {
                            onSelect(row.etf.symbol)
                        } label: {
                            ETFRowView(row: row)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .overlay {
            if model.isLoading && model.quotes.isEmpty {
                ProgressView("Loading quotes…")
            }
        }
        .searchable(text: $model.searchText, prompt: "Symbol or name")
        .navigationTitle("ETF Screener")
        .toolbar {
            ToolbarItem(placement: .primaryAction) { sortMenu }
        }
        .refreshable { await model.refresh() }
        .task {
            await model.refresh()
            guard let interval = refreshInterval, interval > 0 else { return }
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
                if Task.isCancelled { break }
                await model.refresh()
            }
        }
    }

    private var sortMenu: some View {
        Menu {
            Picker("Sort by", selection: $model.sortKey) {
                ForEach(ETFSortKey.allCases) { key in
                    Text(key.rawValue).tag(key)
                }
            }
            Toggle(isOn: $model.ascending) {
                Label("Ascending", systemImage: "arrow.up")
            }
        } label: {
            Label("Sort", systemImage: "arrow.up.arrow.down")
        }
    }

    @ViewBuilder
    private var footer: some View {
        if let updated = model.lastUpdated {
            Text("Updated \(updated.formatted(date: .omitted, time: .standard))")
        }
    }
}

// MARK: - Subviews

private struct CategoryChips: View {
    let categories: [ETFCategory]
    @Binding var selection: ETFCategory?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip("All", isSelected: selection == nil) { selection = nil }
                ForEach(categories) { category in
                    chip(category.rawValue, isSelected: selection == category) {
                        selection = category
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }

    private func chip(_ title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .foregroundColor(isSelected ? .white : .primary)
                .background(
                    Capsule().fill(isSelected ? Color.accentColor : Color.secondary.opacity(0.15))
                )
        }
        .buttonStyle(.plain)
    }
}

private struct ETFRowView: View {
    let row: ETFRow

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(row.etf.symbol)
                    .font(.headline.monospaced())
                Text(row.etf.name)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            if let quote = row.quote {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(quote.price, format: .currency(code: "USD"))
                        .font(.body.monospacedDigit())
                    if let volume = quote.volume {
                        Text("Vol \(volume.formatted(.number.notation(.compactName)))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                ChangeBadge(percent: quote.changePercent)
            } else {
                Text("—").foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

private struct ChangeBadge: View {
    let percent: Double?

    var body: some View {
        Text(label)
            .font(.subheadline.monospacedDigit().weight(.semibold))
            .foregroundColor(.white)
            .frame(minWidth: 72, alignment: .trailing)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(RoundedRectangle(cornerRadius: 6).fill(color))
    }

    private var label: String {
        guard let percent else { return "—" }
        return percent.formatted(.percent.precision(.fractionLength(2)).sign(strategy: .always()))
    }

    private var color: Color {
        guard let percent else { return .gray }
        if percent > 0 { return .green }
        if percent < 0 { return .red }
        return .gray
    }
}

#if DEBUG
struct ETFScreenerView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ETFScreenerView(keyID: "YOUR_KEY_ID", secret: "YOUR_SECRET") { symbol in
                print("Selected \(symbol)")
            }
        }
    }
}
#endif
