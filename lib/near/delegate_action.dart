import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import 'near_format.dart';

/// A NEP-366 delegate action: one call the user signs on the phone, which
/// fliq's relayer submits and pays gas for. Ported from the iPhone app's
/// NEARDelegate.swift, byte for byte.
class DelegateAction {
  const DelegateAction({
    required this.senderId,
    required this.receiverId,
    required this.methodName,
    required this.args,
    required this.gas,
    required this.deposit,
    required this.nonce,
    required this.maxBlockHeight,
    required this.publicKey,
  });

  /// The relayer passes about ten minutes of blocks and refuses more than
  /// 1,200.
  static const lifetimeBlocks = 600;

  /// NEP-461 puts this before the action, so a signed delegate can never be
  /// replayed as a transaction.
  static const signingPrefix = (1 << 30) + 366;
  static const _ed25519 = 0;
  static const _functionCallAction = 2;

  final String senderId;
  final String receiverId;
  final String methodName;
  final List<int> args;
  final BigInt gas;

  /// yoctoNEAR attached to the call.
  final BigInt deposit;
  final BigInt nonce;
  final BigInt maxBlockHeight;

  /// The raw 32-byte ed25519 public key that signs.
  final Uint8List publicKey;

  /// Vault to vault between fliq users. The vault takes exactly one
  /// yoctoNEAR, so only the owner's full-access key can move money.
  factory DelegateAction.vaultTransfer({
    required String from,
    required String to,
    required BigInt units,
    required String vault,
    required BigInt nonce,
    required BigInt blockHeight,
    required Uint8List publicKey,
  }) => DelegateAction(
    senderId: from,
    receiverId: vault,
    methodName: 'transfer',
    args: utf8.encode('{"to_account":"$to","amount":"$units"}'),
    gas: BigInt.from(30000000000000),
    deposit: BigInt.one,
    nonce: nonce,
    maxBlockHeight: blockHeight + BigInt.from(lifetimeBlocks),
    publicKey: publicKey,
  );

  /// Releases a registered cash-out: the vault sends the order's USDC to its
  /// deposit address and nothing else. The vault refuses an amount or address
  /// that differs from the order.
  factory DelegateAction.vaultPayout({
    required String from,
    required String orderId,
    required BigInt units,
    required String depositAddress,
    required String vault,
    required BigInt nonce,
    required BigInt blockHeight,
    required Uint8List publicKey,
  }) => DelegateAction(
    senderId: from,
    receiverId: vault,
    methodName: 'payout',
    args: utf8.encode(
      '{"order_id":"$orderId","amount":"$units",'
      '"deposit_address":"$depositAddress"}',
    ),
    gas: BigInt.from(100000000000000),
    deposit: BigInt.zero,
    nonce: nonce,
    maxBlockHeight: blockHeight + BigInt.from(lifetimeBlocks),
    publicKey: publicKey,
  );

  /// Any vault call the API asked the phone to sign, such as `set_agent`
  /// or `remove_agent`.
  factory DelegateAction.functionCall({
    required String from,
    required String receiverId,
    required String methodName,
    required List<int> args,
    required BigInt gas,
    required BigInt deposit,
    required BigInt nonce,
    required BigInt blockHeight,
    required Uint8List publicKey,
  }) => DelegateAction(
    senderId: from,
    receiverId: receiverId,
    methodName: methodName,
    args: args,
    gas: gas,
    deposit: deposit,
    nonce: nonce,
    maxBlockHeight: blockHeight + BigInt.from(lifetimeBlocks),
    publicKey: publicKey,
  );

  Uint8List get borsh {
    final writer = BorshWriter()
      ..string(senderId)
      ..string(receiverId)
      ..u32(1)
      ..u8(_functionCallAction)
      ..string(methodName)
      ..bytesWithLength(args)
      ..u64(gas)
      ..u128(deposit)
      ..u64(nonce)
      ..u64(maxBlockHeight)
      ..u8(_ed25519)
      ..raw(publicKey);
    return writer.bytes;
  }

  /// What the key signs: sha256 of the NEP-461 prefix and the action.
  Future<Uint8List> signingHash() async {
    final writer = BorshWriter()
      ..u32(signingPrefix)
      ..raw(borsh);
    final hash = await Sha256().hash(writer.bytes);
    return Uint8List.fromList(hash.bytes);
  }

  /// The Borsh `SignedDelegate` that `POST /relays` takes, base64 encoded.
  String signedWith(List<int> signature) {
    final writer = BorshWriter()
      ..raw(borsh)
      ..u8(_ed25519)
      ..raw(signature);
    return base64Encode(writer.bytes);
  }
}
