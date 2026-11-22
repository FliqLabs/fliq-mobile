import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/account_models.dart';
import '../models/rate.dart';
import '../models/transaction.dart';
import '../models/user.dart';
import 'api_exception.dart';
import 'session_store.dart';

/// Talks to the Fliq server.
///
/// Signed-in calls carry the session's access token. Shortly before it
/// expires, or when the server answers 401, the client renews it once with the
/// refresh token and retries.
class FliqApi {
  FliqApi({http.Client? client, SessionStore? sessions, String? baseUrl})
    : _client = client ?? http.Client(),
      sessions = sessions ?? SecureSessionStore(),
      _baseUrl = baseUrl ?? ApiConfig.baseUrl;

  /// The API the app uses. Tests swap this for a fake so they never call
  /// the real server.
  static FliqApi instance = FliqApi();

  /// The free test server can take over a minute to wake up.
  static const timeout = Duration(seconds: 90);
  static const _renewalMargin = Duration(seconds: 60);

  final http.Client _client;
  final String _baseUrl;
  final SessionStore sessions;

  /// Called when the server refuses the session for good, so the app can go
  /// back to sign-in.
  void Function()? onSignedOut;

  Future<bool>? _renewing;

  // ── Public, no sign-in ────────────────────────────────────────────────

  /// Asks the server if it is running and returns its version, e.g. "0.1.0".
  Future<String> checkHealth() async {
    final body = await _send('GET', '/health');
    return body['version'] as String;
  }

  /// The best after-fee rate right now, e.g. naira per 1 USDC.
  Future<Rate> getRate({String token = 'usdc', String currency = 'ngn'}) async {
    return Rate.fromJson(await _send('GET', '/rates/$token/$currency'));
  }

  // ── Sign-in ───────────────────────────────────────────────────────────

  Future<bool> get isSignedIn async => await sessions.read() != null;

  /// Emails a one-time sign-in link. The answer is the same whether or not
  /// the email has an account.
  Future<void> sendEmailLink(String email) async {
    await _send('POST', '/auth/email-links', body: {'email': email});
  }

  /// Exchanges the token from a sign-in link for a session and keeps it.
  Future<User> verifyEmailLink(String token) async {
    final session = Session.fromJson(
      await _send('POST', '/auth/email-links/verify', body: {'token': token}),
    );
    await _store(session);
    return session.user;
  }

  Future<void> signOut() async {
    try {
      await _send('POST', '/auth/logout', auth: true);
    } catch (_) {
      // Signing out locally still works when the server can't be reached.
    }
    await sessions.clear();
  }

  // ── Signed in ─────────────────────────────────────────────────────────

  Future<User> me() async =>
      User.fromJson(await _send('GET', '/me', auth: true));

  Future<VaultBalance> vaultBalance() async =>
      VaultBalance.fromJson(await _send('GET', '/vault', auth: true));

  /// Everything that moved money, newest first.
  Future<List<Transaction>> activity() async {
    final body = await _send(
      'GET',
      '/activity',
      auth: true,
      query: {'limit': '50'},
    );
    final items = body['items'] as List<dynamic>? ?? const [];
    return [
      for (final item in items)
        Transaction.fromActivity(item as Map<String, dynamic>),
    ];
  }

  /// Banks and mobile-money providers in a country, e.g. `ng` or `ke`.
  Future<List<Institution>> institutions(String country) async {
    final body = await _send(
      'GET',
      '/institutions',
      auth: true,
      query: {'country': country},
    );
    return [
      for (final item in body['items'] as List<dynamic>? ?? const [])
        Institution.fromJson(item as Map<String, dynamic>),
    ];
  }

  /// Saved accounts, newest first.
  Future<List<Recipient>> recipients() async {
    final body = await _send('GET', '/recipients', auth: true);
    return [
      for (final item in body['items'] as List<dynamic>? ?? const [])
        Recipient.fromJson(item as Map<String, dynamic>),
    ];
  }

  /// Checks the account with its bank and saves it. Saving one that is
  /// already saved returns the existing one.
  Future<Recipient> saveRecipient({
    required String bankCode,
    required String number,
    required String country,
    bool own = false,
  }) async {
    final saved = Recipient.fromJson(
      await _send(
        'POST',
        '/recipients',
        auth: true,
        body: {'bank': bankCode, 'number': number, 'country': country},
      ),
    );
    if (!own) return saved;
    return Recipient.fromJson(
      await _send(
        'PATCH',
        '/recipients/${saved.id}',
        auth: true,
        body: {'own': true},
      ),
    );
  }

  Future<Limits> limits() async =>
      Limits.fromJson(await _send('GET', '/me/limits', auth: true));

  /// Dollars, or null to remove the limit. A raise or removal waits 24 hours.
  Future<Limits> setDailyLimit(double? dollars) async => Limits.fromJson(
    await _send(
      'PUT',
      '/me/limits',
      auth: true,
      body: {'daily_limit': dollars?.toStringAsFixed(2)},
    ),
  );

  Future<List<DeviceSession>> deviceSessions() async {
    final body = await _send('GET', '/sessions', auth: true);
    return [
      for (final item in body['items'] as List<dynamic>? ?? const [])
        DeviceSession.fromJson(item as Map<String, dynamic>),
    ];
  }

  Future<void> revokeSession(String id) async {
    await _send('DELETE', '/sessions/$id', auth: true);
  }

  /// The notification switches, keyed as the API names them.
  Future<Map<String, dynamic>> notificationSettings() =>
      _send('GET', '/me/notification-settings', auth: true);

  Future<Map<String, dynamic>> saveNotificationSettings(
    Map<String, dynamic> settings,
  ) => _send('PUT', '/me/notification-settings', auth: true, body: settings);

  // ── Plumbing ──────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Object? body,
    bool auth = false,
    Map<String, String>? query,
    bool isRetry = false,
  }) async {
    SessionTokens? tokens;
    if (auth) {
      tokens = await _freshTokens();
      if (tokens == null) throw const ApiException.signedOut();
    }

    final request = http.Request(
      method,
      Uri.parse('$_baseUrl$path').replace(queryParameters: query),
    );
    request.headers['Accept'] = 'application/json';
    request.headers['X-Device-Name'] = 'Android';
    if (tokens != null) {
      request.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
    }
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }

    final http.Response response;
    try {
      response = await http.Response.fromStream(await _client.send(request))
          .timeout(timeout);
    } on Exception {
      // No connection, a timeout, or the server hung up.
      throw const ApiException.offline();
    }

    if (response.statusCode == 401 && tokens != null && !isRetry) {
      if (await _renew(tokens)) {
        return _send(
          method,
          path,
          body: body,
          auth: auth,
          query: query,
          isRetry: true,
        );
      }
      throw const ApiException.signedOut();
    }
    if (response.statusCode >= 400) throw ApiException.fromResponse(response);
    if (response.body.trim().isEmpty) return const {};
    final decoded = jsonDecode(response.body);
    return decoded is Map<String, dynamic> ? decoded : {'items': decoded};
  }

  Future<SessionTokens?> _freshTokens() async {
    final tokens = await sessions.read();
    if (tokens == null) return null;
    if (tokens.expiresAt.difference(DateTime.now()) > _renewalMargin) {
      return tokens;
    }
    return await _renew(tokens) ? sessions.read() : null;
  }

  /// Requests that all meet a 401 at once share one renewal: the server
  /// revokes the whole session when a refresh token is used twice.
  Future<bool> _renew(SessionTokens used) {
    return _renewing ??= _renewOnce(used).whenComplete(() => _renewing = null);
  }

  Future<bool> _renewOnce(SessionTokens used) async {
    final current = await sessions.read();
    if (current == null) return false;
    final alreadyRenewed =
        current.accessToken != used.accessToken &&
        current.expiresAt.difference(DateTime.now()) > _renewalMargin;
    if (alreadyRenewed) return true;
    try {
      final session = Session.fromJson(
        await _send(
          'POST',
          '/auth/refresh',
          body: {'refresh_token': current.refreshToken},
        ),
      );
      await _store(session);
      return true;
    } on ApiException catch (error) {
      if (error.status == 401) {
        await sessions.clear();
        onSignedOut?.call();
      }
      return false;
    }
  }

  Future<void> _store(Session session) => sessions.save(
    SessionTokens(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
      expiresAt: DateTime.now().add(Duration(seconds: session.expiresIn)),
    ),
  );
}
