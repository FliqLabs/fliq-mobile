/// Where the app sends its API requests.
abstract final class ApiConfig {
  static const testUrl = 'https://fliq-yclq.onrender.com/v1';
  static const prodUrl = 'https://api-mainnet-64d65ef4.up.railway.app/v1';

  /// Uses test unless the app is started with
  /// `--dart-define=FLIQ_API_BASE_URL=another-url`.
  static const baseUrl = String.fromEnvironment(
    'FLIQ_API_BASE_URL',
    defaultValue: testUrl,
  );

  /// The NEAR chain the server works on: testnet for the test server,
  /// mainnet for the live one. Can be set with
  /// `--dart-define=FLIQ_NEAR_RPC_URL=...`.
  static const nearRpcUrl = String.fromEnvironment(
    'FLIQ_NEAR_RPC_URL',
    defaultValue: baseUrl == prodUrl
        ? 'https://rpc.mainnet.fastnear.com'
        : 'https://rpc.testnet.near.org',
  );

  /// True when talking to the live server, where money is real.
  static const isLive = baseUrl == prodUrl;
}
