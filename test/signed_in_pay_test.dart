import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fliq/models/payment.dart';
import 'package:fliq/screens/pay/quote_screen.dart';
import 'package:fliq/screens/recipient_flow_screens.dart';
import 'package:fliq/services/account_store.dart';
import 'package:fliq/services/biometric_authenticator.dart';
import 'package:fliq/services/fliq_api.dart';

import 'support/fake_fliq_api.dart';

void main() {
  setUp(() async {
    FliqApi.instance = FakeFliqApi(signedIn: true);
    AccountStore.instance = AccountStore();
    await AccountStore.instance.start();
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
          authenticator: _AlwaysYes(),
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

    await tester.tap(find.byKey(const ValueKey('confirm-payout')));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Sending from Android is almost ready'),
      findsOneWidget,
    );
  });
}

class _AlwaysYes implements BiometricAuthenticator {
  @override
  Future<bool> authenticate() async => true;
}
