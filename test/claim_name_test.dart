import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fliq/models/payment.dart';
import 'package:fliq/near/device_key.dart';
import 'package:fliq/screens/home_screen.dart';
import 'package:fliq/services/account_store.dart';
import 'package:fliq/services/fliq_api.dart';
import 'package:fliq/services/vault_signer.dart';

import 'support/fake_fliq_api.dart';

void main() {
  test('fliq names follow the rules', () {
    expect(validFliqName('@Frank'), 'frank');
    expect(validFliqName('ada-lovelace'), 'ada-lovelace');
    expect(validFliqName('a'), isNull, reason: 'too short');
    expect(validFliqName('-ada'), isNull);
    expect(validFliqName('ada--b'), isNull);
    expect(validFliqName('ada_b'), isNull);
  });

  testWidgets('a new account claims its name with this phone\'s key', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final api = FakeFliqApi(signedIn: true, hasName: false);
    FliqApi.instance = api;
    AccountStore.instance = AccountStore();
    final keys = MemoryDeviceKeys(List.generate(32, (i) => i + 7));
    VaultSigner.instance = VaultSigner(keys: keys);
    await AccountStore.instance.start();
    await AccountStore.instance.ready;

    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Claim your name'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('claim-name-field')),
      'dara',
    );
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    expect(find.text('Taken'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('claim-name-field')),
      'ada',
    );
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    expect(find.text('Available'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('claim-name')));
    await tester.pumpAndSettle();

    expect(api.claimedWithKey, await keys.publicKey());
    expect(AccountStore.instance.handle, 'ada');
    expect(find.text('Claim your name'), findsNothing);
    expect(find.text('Vault balance'), findsOneWidget);
  });
}
