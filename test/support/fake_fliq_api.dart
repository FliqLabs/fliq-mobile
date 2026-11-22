import 'package:fliq/models/rate.dart';
import 'package:fliq/models/transaction.dart';
import 'package:fliq/models/user.dart';
import 'package:fliq/services/api_exception.dart';
import 'package:fliq/services/fliq_api.dart';
import 'package:fliq/services/session_store.dart';

/// A Fliq API that answers from memory, so tests never touch the network.
/// Values are copied from the canonical fixtures in the Fliq repo
/// (`spec/fixtures`).
class FakeFliqApi extends FliqApi {
  FakeFliqApi({bool signedIn = false})
    : super(
        sessions: MemorySessionStore(
          signedIn
              ? SessionTokens(
                  accessToken: 'at_demo_f3k9',
                  refreshToken: 'rf_demo_b81q',
                  expiresAt: DateTime.now().add(const Duration(hours: 1)),
                )
              : null,
        ),
      );

  static const goodToken = 'el_good_token';

  static const user = User(
    userId: 'usr_5d1c0a9e',
    nearAccount: 'frank.fliq.near',
    displayName: 'Frank',
    vault: 'fliq-vault.testnet',
  );

  final sentLinksTo = <String>[];

  @override
  Future<String> checkHealth() async => '0.1.0';

  @override
  Future<Rate> getRate({String token = 'usdc', String currency = 'ngn'}) async {
    return const Rate(
      rate: 1376.32,
      rateBeforeFees: 1383.2,
      provider: 'paycrest',
      providersQuoting: 3,
    );
  }

  @override
  Future<void> sendEmailLink(String email) async => sentLinksTo.add(email);

  @override
  Future<User> verifyEmailLink(String token) async {
    if (token != goodToken) {
      throw const ApiException(
        status: 401,
        code: 'unauthorized',
        message: 'Link expired.',
      );
    }
    await sessions.save(
      SessionTokens(
        accessToken: 'at_demo_f3k9',
        refreshToken: 'rf_demo_b81q',
        expiresAt: DateTime.now().add(const Duration(minutes: 15)),
      ),
    );
    return user;
  }

  @override
  Future<void> signOut() => sessions.clear();

  @override
  Future<User> me() async => user;

  @override
  Future<VaultBalance> vaultBalance() async =>
      const VaultBalance(available: 128.18, total: 128.18);

  @override
  Future<List<Transaction>> activity() async => [
    Transaction.fromActivity(const {
      'activity_id': 'act_po_9c2f71aa',
      'kind': 'payout',
      'status': 'paid',
      'at': '2026-10-29T13:02:32Z',
      'party': {
        'name': 'DARA OKONKWO',
        'near_account': null,
        'institution': '058',
        'account_last4': '6789',
        'photo_url': null,
      },
      'provider': 'paycrest',
      'agent': null,
      'local': {'amount': '68816', 'currency': 'NGN'},
      'usd': '50.00',
      'token': null,
      'seconds': 21,
      'reason': null,
      'ref_id': 'po_9c2f71aa',
    }),
  ];
}
