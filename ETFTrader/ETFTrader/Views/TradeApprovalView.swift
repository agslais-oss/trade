import SwiftUI

/// Final approval screen. The trade is **never** submitted to Alpaca unless
/// the user taps the explicit confirmation button on this view. The button is
/// also gated behind a typed-confirmation toggle to prevent accidental taps.
struct TradeApprovalView: View {
    let asset: Asset
    let request: OrderRequest
    let onConfirm: () -> Void
    let onCancel: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var typedConfirmation: String = ""

    private var requiredPhrase: String { "CONFIRM" }
    private var canConfirm: Bool {
        typedConfirmation.trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased() == requiredPhrase
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("ETF Verified") {
                    LabeledContent("Symbol", value: asset.symbol)
                    LabeledContent("Name", value: asset.name)
                    LabeledContent("Exchange", value: asset.exchange)
                    LabeledContent("Tradable", value: asset.tradable ? "Yes" : "No")
                }

                Section("Order Details") {
                    LabeledContent("Side", value: request.side.rawValue.uppercased())
                    LabeledContent("Quantity", value: request.qty)
                    LabeledContent("Type", value: request.type.rawValue.capitalized)
                    if let limit = request.limitPrice {
                        LabeledContent("Limit Price", value: limit)
                    }
                    LabeledContent("Time in Force", value: request.timeInForce.rawValue.uppercased())
                }

                Section {
                    Text("This will place a real order against your Alpaca paper trading account. The order will not execute until you confirm below.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    TextField("Type CONFIRM to enable", text: $typedConfirmation)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                } header: {
                    Text("Confirmation Required")
                }

                Section {
                    Button {
                        onConfirm()
                        dismiss()
                    } label: {
                        HStack {
                            Spacer()
                            Text("Submit Order").bold()
                            Spacer()
                        }
                    }
                    .disabled(!canConfirm)
                    .tint(request.side == .buy ? .green : .red)
                }
            }
            .navigationTitle("Approve Trade")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                        dismiss()
                    }
                }
            }
            .interactiveDismissDisabled(true)
        }
    }
}
