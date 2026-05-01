# ETFTrader

A SwiftUI iOS app for paper-trading ETFs through the
[Alpaca Markets](https://alpaca.markets) REST API. Built with MVVM, an on-device
backtesting engine, and a strict trade-approval flow that requires explicit
user confirmation before any order is sent to the broker.

> The app talks **only** to the paper-trading endpoint
> (`https://paper-api.alpaca.markets`). It is not configured to place real-money
> orders.

## Features

- **MVVM architecture** — `Models/`, `ViewModels/`, `Views/`, with `Services/`
  for the REST client, Keychain wrapper, and backtest engine.
- **ETF-only trading** — every order goes through `AlpacaAPI.placeOrder`,
  which fetches the asset record and rejects anything that is not flagged as
  an ETF (`etp` attribute, `"ETF"` in the asset name, or a member of the
  curated allowlist in `Asset.swift`).
- **Trade approval screen** — `TradeApprovalView` is the only path to
  submission. It is shown as a non-dismissible sheet, displays the verified
  ETF metadata and full order details, and requires the user to type
  `CONFIRM` before the **Submit Order** button becomes enabled.
- **Local backtesting engine** — three strategies (SMA crossover, RSI mean
  reversion, buy & hold) run entirely on-device against historical bars
  fetched from Alpaca's market-data endpoint. Reports total return, max
  drawdown, win rate, and a trade log.
- **Keychain-backed credentials** — API key and secret are stored using
  `kSecClassGenericPassword` with
  `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`, so credentials never
  sync to iCloud Keychain.

## Project Layout

```
ETFTrader/
├── ETFTrader/
│   ├── App/                    ETFTraderApp.swift, RootView.swift
│   ├── Models/                 Account, Asset, Bar, Order, Position, BacktestResult
│   ├── Services/               KeychainService, AlpacaAPI, BacktestEngine
│   ├── ViewModels/             SettingsVM, AccountVM, TradeVM, BacktestVM
│   ├── Views/                  AccountView, TradeView, TradeApprovalView,
│   │                           BacktestView, SettingsView
│   └── Resources/              Info.plist
├── ETFTraderTests/             BacktestEngineTests, KeychainServiceTests,
│                               TradeViewModelTests
├── project.yml                 XcodeGen project descriptor
└── README.md
```

## Building

You need Xcode 15+ on macOS. The repository ships an `XcodeGen` descriptor
(`project.yml`) instead of a pre-generated `.xcodeproj` so the project is easy
to regenerate and review.

```bash
brew install xcodegen        # one-time
cd ETFTrader
xcodegen generate            # produces ETFTrader.xcodeproj
open ETFTrader.xcodeproj
```

Then in Xcode:

1. Select the **ETFTrader** scheme and an iOS Simulator (iPhone 15+ recommended).
2. **Run**.
3. Open the **Settings** tab and paste your Alpaca paper-trading
   `APCA-API-KEY-ID` and `APCA-API-SECRET-KEY`. They are written to the
   Keychain.

### Running tests

```bash
xcodebuild test \
  -project ETFTrader.xcodeproj \
  -scheme ETFTrader \
  -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Trade Submission Flow

The single rule: **no order is submitted without explicit user confirmation.**

```
TradeView           ▶ user enters symbol / qty / side
   │
   ▼
TradeViewModel.prepareForApproval()
   │   ├─ validates symbol is an ETF (Alpaca asset lookup)
   │   └─ stages OrderRequest, opens TradeApprovalView sheet
   ▼
TradeApprovalView    ▶ user reviews, types "CONFIRM"
   │
   ▼ (only when user taps Submit Order)
TradeViewModel.confirmAndSubmit()
   │
   ▼
AlpacaAPI.placeOrder()
   │   ├─ re-checks asset.isETF (defense in depth)
   │   └─ POSTs to /v2/orders
   ▼
Alpaca paper-trading account
```

The unit tests in `TradeViewModelTests.swift` verify that:

- A non-ETF symbol is rejected before approval.
- `prepareForApproval()` never submits an order.
- `confirmAndSubmit()` is a no-op when the order has not been approved.

## Security Notes

- API credentials live only in the Keychain (`KeychainService.swift`). They are
  never written to `UserDefaults`, logs, or files.
- `NSAllowsArbitraryLoads` is `false`; all traffic uses HTTPS to Alpaca.
- The app targets the paper endpoint by default. To point at live trading you
  would need to change `AlpacaEnvironment.paperTradingBase` in
  `AlpacaAPI.swift` — this is intentionally not exposed in the UI.

## Disclaimer

Educational sample code. ETF classification is best-effort (Alpaca's
`attributes` field, name heuristic, and a curated allowlist). Always verify
orders in the paper account before considering any production use, and never
ship this app pointed at the live trading endpoint without an additional
review.
