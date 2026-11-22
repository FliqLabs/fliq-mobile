import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fliq/near/delegate_action.dart';
import 'package:fliq/near/device_key.dart';
import 'package:fliq/near/near_format.dart';

/// Checks the phone's signing against near-api-js 7.4.0, NEAR's own
/// library. The reference comes from the iPhone app's DelegateTests.swift:
/// `buildDelegateAction` and `encodeSignedDelegate` for the key with seed
/// bytes 1…32. One wrong byte here and the chain would refuse the transfer.
void main() {
  const nearApiJs =
      'GQAAAGZyYW5rLmZsaXFhY2NvdW50LnRlc3RuZXQSAAAAZmxpcS12YXVsdC50ZXN0bmV0AQAAAAIIAAAAdHJhbnNmZXI9AAAAeyJ0b19hY2NvdW50IjoidG9iaS5mbGlxYWNjb3VudC50ZXN0bmV0IiwiYW1vdW50IjoiMjUwMDAwMDAifQDgV+tIGwAAAQAAAAAAAAAAAAAAAAAAACoAAAAAAAAA7BMAAAAAAAAAebVWLo/mVPlAeLES6KmLp5AfhTrmlb7X4OORC60ElmQAm1lt8+6PEeP2edzxGEZE/eXXtRiWRH6P/cVBi1VM+dKBHc18kF7T/y5tyVm9WgM1WtOTxk6itV1GXiXYia/8Bg==';
  final seed = List<int>.generate(32, (i) => i + 1);
  final reference = base64Decode(nearApiJs);

  Future<DelegateAction> transfer() async {
    final public = NearKey.decode(await publicKeyForSeed(seed))!;
    return DelegateAction.vaultTransfer(
      from: 'frank.fliqaccount.testnet',
      to: 'tobi.fliqaccount.testnet',
      units: BigInt.from(25000000),
      vault: 'fliq-vault.testnet',
      nonce: BigInt.from(42),
      blockHeight: BigInt.from(5100 - DelegateAction.lifetimeBlocks),
      publicKey: public,
    );
  }

  test('the action is encoded exactly as near-api-js encodes it', () async {
    final action = await transfer();
    expect(action.borsh, reference.sublist(0, reference.length - 65));
  });

  test('our signed delegate matches near-api-js byte for byte', () async {
    final action = await transfer();
    final hash = await action.signingHash();
    final signature = (await signWithSeed(seed, [hash])).single;
    expect(base64Decode(action.signedWith(signature)), reference);
  });

  test("near-api-js's signature verifies over our signing hash", () async {
    final action = await transfer();
    final hash = await action.signingHash();
    final valid = await Ed25519().verify(
      hash,
      signature: Signature(
        reference.sublist(reference.length - 64),
        publicKey: SimplePublicKey(action.publicKey, type: KeyPairType.ed25519),
      ),
    );
    expect(valid, isTrue);
  });

  test('base58 round-trips keys, including leading zeros', () {
    final bytes = Uint8List.fromList([0, 0, 1, 2, 255, 128]);
    expect(Base58.decode(Base58.encode(bytes)), bytes);
    expect(Base58.encode([0]), '1');
    expect(Base58.decode('0OIl'), isNull, reason: 'not in the alphabet');
  });

  test('USDC amounts turn into exact units', () {
    expect(usdcUnits('50.00'), BigInt.from(50000000));
    expect(usdcUnits('0.01'), BigInt.from(10000));
    expect(usdcUnits('128.183456'), BigInt.from(128183456));
    expect(() => usdcUnits('1.0000001'), throwsFormatException);
  });
}
