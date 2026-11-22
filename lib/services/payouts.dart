import '../models/payment.dart';
import 'account_store.dart';

/// Thrown when the app can't move money yet.
class PayoutNotReady implements Exception {
  const PayoutNotReady(this.message);

  final String message;
}

/// Sends a quoted payout from the vault.
///
/// Moving money needs this phone's own signing key (the vault only obeys
/// transfers signed on the device, behind biometrics). Until that is built,
/// this stops at confirm and says so, so nothing pretends to send.
class Payouts {
  static Payouts instance = Payouts();

  Future<void> send(Quote quote, VerifiedAccount account) async {
    if (!AccountStore.instance.isSignedIn) {
      throw const PayoutNotReady('Sign in to send money.');
    }
    throw const PayoutNotReady(
      'Sending from Android is almost ready. For now, use the fliq iPhone '
      'app to send.',
    );
  }
}

/// Moves dollars from this vault to another fliq user's, instantly and
/// without a fee. Needs the same on-device signing as payouts.
class Transfers {
  static Transfers instance = Transfers();

  Future<void> sendToPerson(Person person, double dollars) async {
    if (!AccountStore.instance.isSignedIn) {
      throw const PayoutNotReady('Sign in to send money.');
    }
    throw const PayoutNotReady(
      'Sending from Android is almost ready. For now, use the fliq iPhone '
      'app to send.',
    );
  }
}
