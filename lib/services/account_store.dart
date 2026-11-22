import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/sample_data.dart';
import '../models/transaction.dart';
import '../models/user.dart';
import 'api_exception.dart';
import 'deposit_addresses.dart';
import 'fliq_api.dart';

/// The signed-in user's profile, balance and activity, shared by every screen.
///
/// Before sign-in (and in tests) it shows the sample data, so the app can be
/// explored without an account.
class AccountStore extends ChangeNotifier {
  AccountStore();

  static AccountStore instance = AccountStore();

  FliqApi get _api => FliqApi.instance;

  bool _isSignedIn = false;
  User? _user;
  VaultBalance? _balance;
  List<Transaction>? _transactions;
  bool _isLoading = false;
  ApiException? _error;

  bool get isSignedIn => _isSignedIn;
  bool get isLoading => _isLoading;

  /// The last load's failure, shown as a quiet message. Old data stays.
  ApiException? get error => _error;
  User? get user => _user;

  String get handle => _isSignedIn ? (_user?.handle ?? '') : SampleData.handle;
  String get nearAccount =>
      _isSignedIn ? (_user?.nearAccount ?? '') : SampleData.nearAccount;
  String get initials =>
      _isSignedIn ? (_user?.initials ?? '') : SampleData.initials;
  String? get displayName => _isSignedIn ? _user?.displayName : null;

  /// Spendable dollars in the vault.
  double get balanceUsd =>
      _isSignedIn ? (_balance?.available ?? 0) : SampleData.vaultBalanceUsd;

  List<Transaction> get transactions =>
      _isSignedIn ? (_transactions ?? const []) : SampleData.transactions;

  /// Checks for a saved session and, if there is one, loads the account.
  Future<void> start() async {
    _isSignedIn = await _api.isSignedIn;
    _api.onSignedOut = _forget;
    notifyListeners();
    // Load in the background; the first screen shows as soon as possible.
    if (_isSignedIn) unawaited(refresh());
  }

  /// Called right after a successful sign-in.
  Future<void> signedIn(User user) async {
    _isSignedIn = true;
    _user = user;
    _api.onSignedOut = _forget;
    notifyListeners();
    await refresh();
  }

  /// Reloads profile, balance and activity together.
  Future<void> refresh() async {
    if (!_isSignedIn || _isLoading) return;
    _isLoading = true;
    notifyListeners();
    try {
      final results = await Future.wait([
        _api.me(),
        if (_user?.hasName ?? true) _api.vaultBalance(),
        _api.activity(),
      ]);
      _user = results.first as User;
      if (results.length == 3) _balance = results[1] as VaultBalance;
      _transactions = results.last as List<Transaction>;
      _error = null;
    } on ApiException catch (error) {
      // A new account has no vault yet; that is not an error worth showing.
      if (error.status != 404) _error = error;
      if (error.isSignedOut) _forget();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _api.signOut();
    _forget();
  }

  void _forget() {
    DepositAddresses.instance.clear();
    _isSignedIn = false;
    _user = null;
    _balance = null;
    _transactions = null;
    _error = null;
    notifyListeners();
  }
}
