import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fliq/models/payment.dart';
import 'package:fliq/near/device_key.dart';
import 'package:fliq/near/near_format.dart';
import 'package:fliq/near/near_rpc.dart';
import 'package:fliq/services/vault_signer.dart';
import 'package:fliq/screens/pay/quote_screen.dart';
import 'package:fliq/screens/recipient_flow_screens.dart';
import 'package:fliq/services/account_store.dart';
import 'package:fliq/services/fliq_api.dart';

import 'support/fake_fliq_api.dart';

void main() {
  setUp(() async {
    FliqApi.instance = FakeFliqApi(signedIn: true);
    AccountStore.instance = AccountStore();
    await AccountStore.instance.start();
    await AccountStore.instance.ready;
  });

  void usePhone(WidgetTester tester) {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets('a fliq name that exists shows who it belongs to', (
    tester,
  ) async {
    usePhone(tester);
    await tester.pumpWidget(const MaterialApp(home: FliqRecipientScreen()));

    await tester.enterText(
      find.byKey(const ValueKey('fliq-recipient-name')),
      '@tobi',
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('fliq-person-found')), findsOneWidget);
    expect(find.text('Tobi A. · tobi.fliq.near'), findsOneWidget);
    expect(find.text('No one on fliq has that name'), findsNothing);
  });

  testWidgets('the quote shows the best route, fees and a held rate', (
    tester,
  ) async {
    usePhone(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: QuoteScreen(
          account: const VerifiedAccount(
            bankCode: '058',
            number: '0123456789',
            accountName: 'DARA OKONKWO',
            institution: 'GTBank',
          ),
          currency: 'NGN',
          amount: 50,
          receiveLocal: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('DARA OKONKWO receives'), findsOneWidget);
    expect(find.text('₦68,816'), findsOneWidget);
    expect(find.text(r'$50.00'), findsOneWidget);
    expect(find.text(r'$1 = ₦1,376.32'), findsOneWidget);
    expect(find.text('₦344'), findsOneWidget);
    expect(find.text('Best of 4'), findsOneWidget);
    // 50 × (1376.32 − 1370.08) more than the next live provider.
    expect(find.text('+₦312'), findsOneWidget);
    expect(find.text('Paid out by Paycrest'), findsOneWidget);
    expect(find.text('Rate held for'), findsOneWidget);
  });

  testWidgets('confirm signs the vault payout and shows Paid', (tester) async {
    usePhone(tester);
    final api = FliqApi.instance as FakeFliqApi;
    final keys = MemoryDeviceKeys(List.generate(32, (i) => i + 1));
    VaultSigner.instance = VaultSigner(
      keys: keys,
      rpcOverride: _FakeRpc(publicKey: await keys.publicKey()),
      pollInterval: Duration.zero,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: QuoteScreen(
          account: VerifiedAccount(
            bankCode: '058',
            number: '0123456789',
            accountName: 'DARA OKONKWO',
            institution: 'GTBank',
          ),
          currency: 'NGN',
          amount: 50,
          receiveLocal: false,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('confirm-payout')));
    await tester.pumpAndSettle();

    // One signature, for exactly the order the server registered.
    expect(keys.signatures, 1);
    expect(api.relayed, hasLength(1));
    final signed = base64Decode(api.relayed.single);
    final text = utf8.decode(signed, allowMalformed: true);
    expect(text, contains('"order_id":"po_9c2f71aa","amount":"50000000"'));
    expect(text, contains('po-9c2f71aa.paycrest.testnet'));

    // The signature is valid for the action it carries.
    final action = signed.sublist(0, signed.length - 65);
    final prefix = Uint8List(4)
      ..buffer.asByteData().setUint32(0, (1 << 30) + 366, Endian.little);
    final hash = await Sha256().hash([...prefix, ...action]);
    final valid = await Ed25519().verify(
      hash.bytes,
      signature: Signature(
        signed.sublist(signed.length - 64),
        publicKey: SimplePublicKey(
          NearKey.decode(await keys.publicKey())!,
          type: KeyPairType.ed25519,
        ),
      ),
    );
    expect(valid, isTrue);

    expect(find.text('Paid'), findsOneWidget);
    expect(find.text('₦68,816'), findsOneWidget);
    expect(find.text('000013251029140213'), findsOneWidget);
    expect(find.text('Share receipt'), findsOneWidget);
  });

  testWidgets('a phone whose key is not on the account says so', (
    tester,
  ) async {
    usePhone(tester);
    final keys = MemoryDeviceKeys(List.generate(32, (i) => i + 1));
    VaultSigner.instance = VaultSigner(
      keys: keys,
      rpcOverride: _FakeRpc(publicKey: 'ed25519:someoneElse'),
      pollInterval: Duration.zero,
    );
    await tester.pumpWidget(const MaterialApp(home: FliqRecipientScreen()));
    await tester.enterText(
      find.byKey(const ValueKey('fliq-recipient-name')),
      'tobi',
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('fliq-amount-key-5')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('fliq-recipient-pay')));
    await tester.pumpAndSettle();

    expect(keys.signatures, 0, reason: 'nothing is signed');
    expect(
      find.textContaining("This phone can't move money for this account"),
      findsOneWidget,
    );
  });

  testWidgets('paying a fliq user signs a vault transfer', (tester) async {
    usePhone(tester);
    final api = FliqApi.instance as FakeFliqApi;
    final keys = MemoryDeviceKeys(List.generate(32, (i) => i + 1));
    VaultSigner.instance = VaultSigner(
      keys: keys,
      rpcOverride: _FakeRpc(publicKey: await keys.publicKey()),
      pollInterval: Duration.zero,
    );
    await tester.pumpWidget(const MaterialApp(home: FliqRecipientScreen()));
    await tester.enterText(
      find.byKey(const ValueKey('fliq-recipient-name')),
      'tobi',
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('fliq-amount-key-5')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('fliq-recipient-pay')));
    await tester.pumpAndSettle();

    final text = utf8.decode(
      base64Decode(api.relayed.single),
      allowMalformed: true,
    );
    expect(text, contains('"to_account":"tobi.fliq.near","amount":"5000000"'));
    expect(text, contains('fliq-vault.testnet'));
    expect(find.text('Sent'), findsOneWidget);
    expect(find.text(r'$5.00'), findsOneWidget);
  });
}

/// A NEAR chain where only [publicKey] is on the account, at nonce 41.
class _FakeRpc extends NearRpc {
  _FakeRpc({required this.publicKey});

  final String publicKey;

  @override
  Future<BigInt> accessKeyNonce(String account, String key) async {
    if (key != publicKey) {
      throw NearRpcException('access key $key does not exist while viewing');
    }
    return BigInt.from(41);
  }

  @override
  Future<BigInt> finalBlockHeight() async => BigInt.from(278837980);
}
