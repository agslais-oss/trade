import SwiftUI

struct BacktestView: View {
    @StateObject private var vm = BacktestViewModel()

    var body: some View {
        NavigationStack {
            Form {
                Section("Universe") {
                    TextField("ETF Symbol (e.g. SPY)", text: $vm.symbol)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                    Stepper("Lookback: \(vm.lookbackDays) days",
                            value: $vm.lookbackDays, in: 30...1825, step: 30)
                }

                Section("Strategy") {
                    Picker("Strategy", selection: $vm.params.strategy) {
                        ForEach(BacktestStrategy.allCases) { Text($0.rawValue).tag($0) }
                    }
                    if vm.params.strategy == .smaCrossover {
                        Stepper("Fast SMA: \(vm.params.fastPeriod)",
                                value: $vm.params.fastPeriod, in: 2...100)
                        Stepper("Slow SMA: \(vm.params.slowPeriod)",
                                value: $vm.params.slowPeriod, in: 5...250)
                    } else if vm.params.strategy == .rsiMeanReversion {
                        Stepper("RSI Period: \(vm.params.rsiPeriod)",
                                value: $vm.params.rsiPeriod, in: 2...50)
                        Stepper("Oversold: \(Int(vm.params.rsiOversold))",
                                value: $vm.params.rsiOversold, in: 5...45, step: 1)
                        Stepper("Overbought: \(Int(vm.params.rsiOverbought))",
                                value: $vm.params.rsiOverbought, in: 55...95, step: 1)
                    }
                    HStack {
                        Text("Initial Capital")
                        Spacer()
                        TextField("$", value: $vm.params.initialCapital, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 120)
                    }
                }

                Section {
                    Button {
                        Task { await vm.run() }
                    } label: {
                        HStack {
                            Spacer()
                            if vm.isRunning {
                                ProgressView()
                            } else {
                                Text("Run Backtest").bold()
                            }
                            Spacer()
                        }
                    }
                    .disabled(vm.isRunning)
                }

                if let err = vm.errorMessage {
                    Section { Text(err).foregroundStyle(.red).font(.footnote) }
                }

                if let result = vm.result {
                    Section("Results — \(result.symbol)") {
                        LabeledContent("Strategy", value: result.strategy)
                        LabeledContent("Initial", value: currency(result.initialCapital))
                        LabeledContent("Final", value: currency(result.finalEquity))
                        LabeledContent("Return", value: percent(result.totalReturnPercent))
                        LabeledContent("Max Drawdown", value: percent(result.maxDrawdown))
                        LabeledContent("Win Rate", value: percent(result.winRate * 100))
                        LabeledContent("Trades", value: "\(result.trades.count)")
                    }
                    if !result.trades.isEmpty {
                        Section("Trade Log") {
                            ForEach(result.trades) { t in
                                HStack {
                                    Text(t.side.rawValue.uppercased())
                                        .foregroundStyle(t.side == .buy ? .green : .red)
                                        .font(.caption.bold())
                                    Text(date(t.date)).font(.caption)
                                    Spacer()
                                    Text(String(format: "%.2f x %.0f", t.price, t.qty))
                                        .font(.caption)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Backtest")
        }
    }

    private func currency(_ v: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "USD"
        return f.string(from: NSNumber(value: v)) ?? "$0"
    }

    private func percent(_ v: Double) -> String { String(format: "%+.2f%%", v) }

    private func date(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: d)
    }
}
