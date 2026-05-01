import SwiftUI

struct RootView: View {
    @EnvironmentObject var settings: SettingsViewModel

    var body: some View {
        TabView {
            AccountView()
                .tabItem { Label("Account", systemImage: "person.crop.circle") }

            TradeView()
                .tabItem { Label("Trade", systemImage: "arrow.left.arrow.right") }

            BacktestView()
                .tabItem { Label("Backtest", systemImage: "chart.line.uptrend.xyaxis") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gear") }
        }
        .overlay(alignment: .top) {
            if !settings.isConfigured {
                Text("API keys not configured — open Settings")
                    .font(.footnote)
                    .padding(8)
                    .background(.yellow.opacity(0.85))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .padding(.top, 4)
            }
        }
    }
}
