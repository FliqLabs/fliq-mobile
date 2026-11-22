import '../data/sample_data.dart';
import '../models/crypto.dart';
import '../models/deposit.dart';
import 'account_store.dart';
import 'api_exception.dart';
import 'fliq_api.dart';

/// Hands out the address to show for a coin on a network.
///
/// Signed in, it is a real address the server reserved, kept while it is
/// still open so switching screens doesn't reserve a new one each time.
/// Signed out, it is a demo address, marked so nobody sends money to it.
class DepositAddresses {
  static DepositAddresses instance = DepositAddresses();

  final _cache = <String, DepositAddress>{};
  List<DepositSource>? _sources;

  /// The API's chain id for a network, e.g. "BNB Smart Chain" → `bnb`.
  static String chainId(CryptoNetwork network) => switch (network.name) {
    'BNB Smart Chain' => 'bnb',
    _ => network.name.toLowerCase(),
  };

  void clear() {
    _cache.clear();
    _sources = null;
  }

  Future<DepositAddress> addressFor(
    CryptoAsset asset,
    CryptoNetwork network, {
    bool fresh = false,
  }) async {
    final account = AccountStore.instance;
    if (!account.isSignedIn) return _demo(asset, network);

    final token = asset.symbol.toLowerCase();
    final chain = chainId(network);
    if (chain == 'near') {
      // USDC on NEAR goes straight to the user's own account.
      return DepositAddress(address: account.nearAccount, minimum: '0.01');
    }

    final key = '$token/$chain';
    final cached = _cache[key];
    final stillOpen =
        cached?.reservedUntil?.isAfter(
          DateTime.now().add(const Duration(minutes: 2)),
        ) ??
        cached != null;
    if (!fresh && cached != null && stillOpen) return cached;

    _sources ??= await FliqApi.instance.depositSources();
    final source = _sources!
        .where((s) => s.token == token && s.chain == chain)
        .firstOrNull;
    if (source == null || !source.available) {
      throw ApiException(
        code: 'unavailable',
        message:
            "${asset.symbol} on ${network.name} isn't available right now. "
            'Try another network.',
      );
    }
    if (source.direct) {
      return DepositAddress(
        address: source.address ?? account.nearAccount,
        minimum: source.minimum,
      );
    }
    final address = await FliqApi.instance.reserveDeposit(
      token: token,
      chain: chain,
      minimum: source.minimum,
    );
    _cache[key] = address;
    return address;
  }

  DepositAddress _demo(CryptoAsset asset, CryptoNetwork network) {
    final lifetime = SampleData.addressLifetime(network);
    return DepositAddress(
      address: SampleData.depositAddress(network),
      minimum: SampleData.minimumDeposit(asset, network).split(' ').first,
      reservedUntil: lifetime == null ? null : DateTime.now().add(lifetime),
      isDemo: true,
    );
  }
}
