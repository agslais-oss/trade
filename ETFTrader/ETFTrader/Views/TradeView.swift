import SwiftUI

struct TradeView: View {
    @StateObject private var vm = TradeViewModel()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Symbol (e.g. SPY)", text: $vm.symbol)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                    Picker("Side", selection: $vm.side) {
                        ForEach(OrderSide.allCases) { Text($0.rawValue.capitalized).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    TextField("Quantity", text: $vm.qty)
                        .keyboardType(.decimalPad)
                    Picker("Order Type", selection: $vm.orderType) {
                        ForEach(OrderType.allCases) { Text($0.rawValue.capitalized).tag($0) }
                    }
                    if vm.orderType == .limit {
                        TextField("Limit Price", text: $vm.limitPrice)
                            .keyboardType(.decimalPad)
                    }
                    Picker("Time in Force", selection: $vm.timeInForce) {
                        ForEach(TimeInForce.allCases) { Text($0.rawValue.uppercased()).tag($0) }
                    }
                } header: {
                    Text("Order")
                } footer: {
                    Text("ETFs only. The order is staged for review and will not be sent until you tap Confirm in the next screen.")
                }

                Section {
                    Button {
                        Task { await vm.prepareForApproval() }
                    } label: {
                        HStack {
                            Spacer()
                            if vm.isWorking {
                                ProgressView()
                            } else {
                                Text("Review Order").bold()
                            }
                            Spacer()
                        }
                    }
                    .disabled(vm.isWorking)
                }

                if let err = vm.errorMessage {
                    Section { Text(err).foregroundStyle(.red).font(.footnote) }
                }

                if let order = vm.lastOrder {
                    Section("Last Submitted") {
                        LabeledContent("Symbol", value: order.symbol)
                        LabeledContent("Side", value: order.side)
                        LabeledContent("Qty", value: order.qty ?? "-")
                        LabeledContent("Status", value: order.status)
                        LabeledContent("ID", value: order.id).font(.caption)
                    }
                }
            }
            .navigationTitle("Trade")
            .sheet(isPresented: $vm.pendingApproval) {
                if let asset = vm.validatedAsset, let request = vm.buildRequest() {
                    TradeApprovalView(
                        asset: asset,
                        request: request,
                        onConfirm: { Task { await vm.confirmAndSubmit() } },
                        onCancel: { vm.cancelApproval() }
                    )
                }
            }
        }
    }
}
