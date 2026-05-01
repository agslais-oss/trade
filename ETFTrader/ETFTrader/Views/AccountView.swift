import SwiftUI

struct AccountView: View {
    @StateObject private var vm = AccountViewModel()

    var body: some View {
        NavigationStack {
            List {
                if let account = vm.account {
                    Section("Account") {
                        LabeledContent("Status", value: account.status)
                        LabeledContent("Equity", value: format(account.equityValue))
                        LabeledContent("Cash", value: format(account.cashValue))
                        LabeledContent("Buying Power", value: format(account.buyingPowerValue))
                    }
                }

                Section("Positions") {
                    if vm.positions.isEmpty {
                        Text("No open positions").foregroundStyle(.secondary)
                    } else {
                        ForEach(vm.positions) { p in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(p.symbol).font(.headline)
                                    Spacer()
                                    Text(format(p.marketValueValue)).font(.headline)
                                }
                                HStack {
                                    Text("\(p.qty) shares @ \(p.avgEntryPrice)")
                                        .font(.caption).foregroundStyle(.secondary)
                                    Spacer()
                                    Text(formatPercent(p.unrealizedPLPercent))
                                        .font(.caption)
                                        .foregroundStyle(p.unrealizedPLValue >= 0 ? .green : .red)
                                }
                            }
                        }
                    }
                }

                Section("Recent Orders") {
                    if vm.orders.isEmpty {
                        Text("No orders yet").foregroundStyle(.secondary)
                    } else {
                        ForEach(vm.orders.prefix(20)) { o in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("\(o.side.uppercased()) \(o.symbol)").font(.headline)
                                    Spacer()
                                    Text(o.status).font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Text("Qty \(o.qty ?? "-") · \(o.type)")
                                    .font(.caption).foregroundStyle(.secondary)
                                if o.status == "new" || o.status == "accepted" {
                                    Button("Cancel", role: .destructive) {
                                        Task { await vm.cancelOrder(o.id) }
                                    }.font(.caption)
                                }
                            }
                        }
                    }
                }

                if let err = vm.errorMessage {
                    Section { Text(err).foregroundStyle(.red).font(.footnote) }
                }
            }
            .navigationTitle("Account")
            .refreshable { await vm.refresh() }
            .task { await vm.refresh() }
            .overlay {
                if vm.isLoading && vm.account == nil {
                    ProgressView()
                }
            }
        }
    }

    private func format(_ value: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "USD"
        return f.string(from: NSNumber(value: value)) ?? "$0.00"
    }

    private func formatPercent(_ value: Double) -> String {
        String(format: "%+.2f%%", value)
    }
}
