# Fliq

Flutter app for the Fliq mobile experience.

## Project layout

- `lib/app.dart` — app setup and dependency wiring
- `lib/main.dart` — app entry point
- `lib/data/` — sample data (balance, rates, transactions, addresses, bank
  lists). This is the one place to swap for real API responses.
- `lib/models/` — plain data classes (transactions, coins and networks)
- `lib/screens/` — full-page screens
- `lib/screens/receive/` — ways to get paid: bank transfer, fliq name,
  external wallet (coin → network → address) and the Receive Tokens sheet
- `lib/screens/settings/` — settings screens, one file per area, plus shared
  settings widgets in `settings_widgets.dart`
- `lib/config/` — which server the app talks to (test by default)
- `lib/services/` — the Fliq API client, sign-in session, account data,
  deposits, payouts, transfers and agents
- `lib/near/` — this phone's own NEAR key and signing (checked byte for byte
  against near-api-js in `test/near_signing_test.dart`)
- `lib/theme/` — shared app theme
- `lib/utils/` — plain Dart helpers (e.g. keypad amount rules)
- `lib/widgets/` — reusable UI components
- `assets/videos/` — bundled app video

## Run and test

```sh
flutter pub get
flutter run
flutter test
```

The welcome screen uses the bundled, muted looping video. The existing-account
action opens the local biometric unlock screen. The current wordmark is a
temporary recreation and can be replaced when the official logo asset is
available.

## Servers

`flutter run` uses the **test** server (testnet, fake money). For the live
server add
`--dart-define=FLIQ_API_BASE_URL=https://api-mainnet-64d65ef4.up.railway.app/v1`.
Publishing steps are in [RELEASING.md](RELEASING.md).
