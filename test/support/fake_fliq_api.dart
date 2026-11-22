import 'package:fliq/models/account_models.dart';
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
  final recipientsList = <Recipient>[
    const Recipient(
      id: 'rcp_5d1c0a9e',
      accountName: 'DARA OKONKWO',
      bankName: 'GTBank',
      last4: '6789',
    ),
  ];
  Limits currentLimits = const Limits();
  final revokedSessions = <String>[];
  Map<String, dynamic> notifications = {
    'received': true,
    'payout_paid': true,
    'payout_refunded': true,
    'agent_paid': true,
    'agent_refused': true,
    'cap_almost_reached': true,
    'rate_alert': {'enabled': false, 'currency': 'NGN', 'above': 1400},
    'weekly_summary': false,
  };

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

  @override
  Future<List<Institution>> institutions(String country) async =>
      country == 'ke'
      ? const [Institution(code: '68', name: 'Equity Bank')]
      : const [
          Institution(code: '058', name: 'GTBank'),
          Institution(code: '044', name: 'Access Bank'),
        ];

  @override
  Future<List<Recipient>> recipients() async => List.of(recipientsList);

  @override
  Future<Recipient> saveRecipient({
    required String bankCode,
    required String number,
    required String country,
    bool own = false,
  }) async {
    if (number == '0000000000') {
      throw const ApiException(
        status: 404,
        code: 'not_found',
        message: 'Account not found.',
      );
    }
    final saved = Recipient(
      id: 'rcp_new',
      accountName: 'FRANK OKAFOR',
      bankName: bankCode == '044' ? 'Access Bank' : 'GTBank',
      last4: number.substring(number.length - 4),
      own: own,
    );
    recipientsList.insert(0, saved);
    return saved;
  }

  @override
  Future<Limits> limits() async => currentLimits;

  @override
  Future<Limits> setDailyLimit(double? dollars) async {
    final raising =
        currentLimits.dailyLimit != null &&
        (dollars == null || dollars > currentLimits.dailyLimit!);
    currentLimits = raising
        ? Limits(
            dailyLimit: currentLimits.dailyLimit,
            pendingLimit: dollars,
            pendingAt: DateTime.now().add(const Duration(hours: 24)),
          )
        : Limits(dailyLimit: dollars);
    return currentLimits;
  }

  @override
  Future<List<DeviceSession>> deviceSessions() async => [
    for (final session in [
      DeviceSession(
        id: 'ses_this',
        device: 'Pixel 9',
        current: true,
        lastActiveAt: DateTime.now(),
      ),
      DeviceSession(
        id: 'ses_mac',
        device: 'MacBook Pro · Safari',
        current: false,
        lastActiveAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ])
      if (!revokedSessions.contains(session.id)) session,
  ];

  @override
  Future<void> revokeSession(String id) async => revokedSessions.add(id);

  @override
  Future<Map<String, dynamic>> notificationSettings() async =>
      Map.of(notifications);

  @override
  Future<Map<String, dynamic>> saveNotificationSettings(
    Map<String, dynamic> settings,
  ) async => notifications = Map.of(settings);
}
