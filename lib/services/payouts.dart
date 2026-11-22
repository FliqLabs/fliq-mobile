import '../models/payment.dart';
import '../near/delegate_action.dart';
import '../near/near_format.dart';
import 'account_store.dart';
import 'fliq_api.dart';
import 'vault_signer.dart';

/// Thrown when the app can't move money for this person (signed out, or no
/// fliq name yet).
class PayoutNotReady implements Exception {
  const PayoutNotReady(this.message);

  final String message;
}

/// Sends a quoted cash-out to a bank or mobile-money account.
///
/// The server registers the order; then this phone signs the vault's
/// `payout` call behind biometrics, so only the owner can release money.
class Payouts {
  static Payouts instance = Payouts();

  /// Registers, releases and follows the payout until the bank answers or
  /// [patience] runs out. [onReleased] runs once the money has left.
  Future<Payout> send(
    Quote quote,
    VerifiedAccount account, {
    void Function()? onReleased,
    Duration patience = const Duration(minutes: 2),
  }) async {
    final user = _readyUser();
    final api = FliqApi.instance;
    final payout = await api.createPayout(
      quoteId: quote.quoteId,
      account: account,
      idempotencyKey: 'payout-${quote.quoteId}',
    );
    if (payout.depositChain == 'near' && !payout.isFinished) {
      await VaultSigner.instance.submit(
        sender: user.nearAccount!,
        reason: 'Send ${quote.currency} to ${account.accountName}',
        build: (nonce, height, key) => DelegateAction.vaultPayout(
          from: user.nearAccount!,
          orderId: payout.payoutId,
          units: usdcUnits(payout.depositAmount),
          depositAddress: payout.depositAddress,
          vault: user.vault!,
          nonce: nonce,
          blockHeight: height,
          publicKey: key,
        ),
      );
    }
    onReleased?.call();
    return follow(payout.payoutId, patience: patience);
  }

  /// Asks the server about the payout every few seconds until it is paid,
  /// refunded or failed, or [patience] runs out.
  Future<Payout> follow(
    String payoutId, {
    Duration patience = const Duration(minutes: 2),
    Duration every = const Duration(seconds: 3),
  }) async {
    final until = DateTime.now().add(patience);
    var payout = await FliqApi.instance.payout(payoutId);
    while (!payout.isFinished && DateTime.now().isBefore(until)) {
      await Future<void>.delayed(every);
      payout = await FliqApi.instance.payout(payoutId);
    }
    return payout;
  }
}

/// Moves dollars from this vault to another fliq user's, instantly and
/// without a fee.
class Transfers {
  static Transfers instance = Transfers();

  Future<RelayResult> sendToPerson(
    Person person,
    double dollars, {
    String? requestCode,
  }) async {
    final user = _readyUser();
    return VaultSigner.instance.submit(
      sender: user.nearAccount!,
      reason: 'Pay @${person.handle}',
      requestCode: requestCode,
      build: (nonce, height, key) => DelegateAction.vaultTransfer(
        from: user.nearAccount!,
        to: person.nearAccount,
        units: usdcUnits(dollars.toStringAsFixed(2)),
        vault: user.vault!,
        nonce: nonce,
        blockHeight: height,
        publicKey: key,
      ),
    );
  }
}

/// The signed-in user, if they can move money at all.
_ReadyUser _readyUser() {
  final account = AccountStore.instance;
  final user = account.user;
  if (!account.isSignedIn || user == null) {
    throw const PayoutNotReady('Sign in to send money.');
  }
  if (user.nearAccount == null || user.vault == null) {
    throw const PayoutNotReady('Choose your fliq name first.');
  }
  return _ReadyUser(user.nearAccount, user.vault);
}

class _ReadyUser {
  const _ReadyUser(this.nearAccount, this.vault);

  final String? nearAccount;
  final String? vault;
}
