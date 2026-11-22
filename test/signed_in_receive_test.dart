import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fliq/data/sample_data.dart';
import 'package:fliq/screens/pay_link_screen.dart';
import 'package:fliq/screens/receive/external_wallet_pages.dart';
import 'package:fliq/services/account_store.dart';
import 'package:fliq/services/deposit_addresses.dart';
import 'package:fliq/services/fliq_api.dart';

import 'support/fake_fliq_api.dart';

void main() {
  late FakeFliqApi api;

  setUp(() async {
    api = FakeFliqApi(signedIn: true);
    FliqApi.instance = api;
    AccountStore.instance = AccountStore();
    DepositAddresses.instance = DepositAddresses();
    await AccountStore.instance.start();
    await AccountStore.instance.ready;
  });

  void usePhone(WidgetTester tester) {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Widget sheetHost(Widget page) => MaterialApp(home: Scaffold(body: page));

  testWidgets('signed in, the address comes from the server', (tester) async {
    usePhone(tester);
    await tester.pumpWidget(
      sheetHost(
        const ReceiveAddressPage(
          asset: SampleData.usdc,
          network: SampleData.solana,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(api.reserved, ['usdc/solana']);
    expect(find.byKey(const ValueKey('demo-address-warning')), findsNothing);
    expect(find.text('7xKqWmP3v…wMk2r'), findsOneWidget);
    expect(find.text('1.00 USDC'), findsOneWidget);
    expect(find.text(r'≈ $0.02'), findsOneWidget);
  });

  testWidgets('the same address is reused while it is open', (tester) async {
    await DepositAddresses.instance.addressFor(
      SampleData.usdc,
      SampleData.solana,
    );
    await DepositAddresses.instance.addressFor(
      SampleData.usdc,
      SampleData.solana,
    );
    expect(api.reserved, ['usdc/solana']);
  });

  testWidgets('USDC on NEAR is your own account, nothing reserved', (
    tester,
  ) async {
    final address = await DepositAddresses.instance.addressFor(
      SampleData.usdc,
      SampleData.near,
    );
    expect(address.address, 'frank.fliq.near');
    expect(api.reserved, isEmpty);
  });

  testWidgets('a network that is off right now says so', (tester) async {
    usePhone(tester);
    await tester.pumpWidget(
      sheetHost(
        const ReceiveAddressPage(
          asset: SampleData.usdt,
          network: SampleData.tron,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('address-problem')), findsOneWidget);
    expect(find.textContaining("isn't available right now"), findsOneWidget);
  });

  testWidgets('signed in, the pay link is created by the server', (
    tester,
  ) async {
    usePhone(tester);
    await tester.pumpWidget(
      const MaterialApp(home: PayLinkScreen(amountUsd: 55)),
    );
    await tester.pumpAndSettle();

    expect(api.createdRequests, [55]);
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('pay-link-url'))).data,
      'pay.fliq.money/frank/7f3a',
    );
    expect(find.textContaining('Demo link'), findsNothing);
  });
}
