import 'dart:typed_data';

import '../models/payment.dart';
import '../near/delegate_action.dart';
import '../near/device_key.dart';
import '../near/near_format.dart';
import '../near/near_rpc.dart';
import 'fliq_api.dart';

/// Why money didn't move.
class TransferProblem implements Exception {
  const TransferProblem(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Signs one vault call with this phone's key behind biometrics, hands it to
/// `POST /relays`, and follows it until the chain answers. Ported from the
/// iPhone app's DelegateRelay.
class VaultSigner {
  VaultSigner({
    this.apiOverride,
    this.rpcOverride,
    DeviceKeys? keys,
    this.pollInterval = const Duration(milliseconds: 1500),
    this.pollAttempts = 20,
  }) : keys = keys ?? SecureDeviceKeys();

  static VaultSigner instance = VaultSigner();

  /// Set in tests; otherwise the app-wide API and RPC are used.
  final FliqApi? apiOverride;
  final NearRpc? rpcOverride;
  final DeviceKeys keys;
  final Duration pollInterval;
  final int pollAttempts;

  FliqApi get api => apiOverride ?? FliqApi.instance;
  NearRpc get rpc => rpcOverride ?? NearRpc.instance;

  /// Whether this phone's key can move money for [account] right now.
  Future<bool> canSignFor(String account) async =>
      rpc.hasAccessKey(account, await keys.publicKey());

  Future<RelayResult> submit({
    required String sender,
    required String reason,
    required DelegateAction Function(
      BigInt nonce,
      BigInt blockHeight,
      Uint8List publicKey,
    )
    build,
    String? requestCode,
  }) async {
    final publicKey = await keys.publicKey();
    final rawKey = NearKey.decode(publicKey);
    if (rawKey == null) throw const TransferProblem('This phone has no key.');

    final BigInt nonce;
    final BigInt height;
    try {
      nonce = await rpc.accessKeyNonce(sender, publicKey);
      height = await rpc.finalBlockHeight();
    } on NearRpcException catch (error) {
      if (error.isUnknownAccessKey) {
        throw const TransferProblem(
          "This phone can't move money for this account yet. Accounts made "
          'on another phone need passkeys on Android, which are coming.',
        );
      }
      throw const TransferProblem(
        "Couldn't reach the NEAR network. Check your connection.",
      );
    }

    final action = build(nonce + BigInt.one, height, rawKey);
    final hash = await action.signingHash();
    final signature = (await keys.sign([hash], reason: reason)).single;
    final submitted = await api.relay(
      action.signedWith(signature),
      requestCode: requestCode,
    );
    return follow(submitted);
  }

  /// Polls a relayed call until the chain answers.
  Future<RelayResult> follow(RelayResult submitted) async {
    var result = submitted;
    for (var i = 0; i < pollAttempts && result.isPending; i++) {
      await Future<void>.delayed(pollInterval);
      result = await api.relayResult(result.delegateHash);
    }
    if (result.succeeded) return result;
    if (result.isPending) {
      throw const TransferProblem(
        'Still going through. Check Activity in a minute.',
      );
    }
    throw TransferProblem(
      result.failures.isEmpty
          ? 'The vault refused the transfer. Nothing moved.'
          : result.failures.first,
    );
  }
}
