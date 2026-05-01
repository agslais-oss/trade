import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var vm: SettingsViewModel
    @State private var revealSecret = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("APCA-API-KEY-ID", text: $vm.apiKeyId)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                    HStack {
                        if revealSecret {
                            TextField("APCA-API-SECRET-KEY", text: $vm.apiSecret)
                                .autocorrectionDisabled()
                        } else {
                            SecureField("APCA-API-SECRET-KEY", text: $vm.apiSecret)
                        }
                        Button {
                            revealSecret.toggle()
                        } label: {
                            Image(systemName: revealSecret ? "eye.slash" : "eye")
                        }
                        .buttonStyle(.borderless)
                    }
                } header: {
                    Text("Alpaca Paper Trading")
                } footer: {
                    Text("Credentials are stored in the iOS Keychain (this device only) and used to authenticate with paper-api.alpaca.markets.")
                }

                Section {
                    Button("Save", action: vm.save)
                        .disabled(vm.apiKeyId.isEmpty || vm.apiSecret.isEmpty)
                    Button("Clear from Keychain", role: .destructive, action: vm.clear)
                        .disabled(!vm.isConfigured)
                }

                if let msg = vm.statusMessage {
                    Section { Text(msg).font(.footnote) }
                }

                Section("About") {
                    LabeledContent("Environment", value: "Paper Trading")
                    LabeledContent("Endpoint", value: "paper-api.alpaca.markets")
                    LabeledContent("Asset Class", value: "ETFs only")
                }
            }
            .navigationTitle("Settings")
        }
    }
}
