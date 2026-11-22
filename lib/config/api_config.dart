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
}
