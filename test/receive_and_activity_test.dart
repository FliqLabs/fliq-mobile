import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fliq/screens/home_screen.dart';
import 'package:fliq/screens/pay_link_screen.dart';
import 'package:fliq/screens/request_amount_screen.dart';
import 'package:fliq/screens/receive/bank_transfer_deposit_screen.dart';
import 'package:fliq/screens/receive/external_wallet_pages.dart';
import 'package:fliq/screens/receive/fliq_name_page.dart';
import 'package:fliq/screens/receive/receive_tokens_sheet.dart';
import 'package:fliq/screens/recipient_flow_screens.dart';
import 'package:fliq/screens/settings/agents_settings_screen.dart';
import 'package:fliq/screens/settings/security_settings_screen.dart';
import 'package:fliq/screens/settings/settings_screen.dart';
import 'package:fliq/screens/welcome_screen.dart';
import 'package:fliq/services/biometric_authenticator.dart';
import 'package:fliq/services/account_store.dart';
import 'package:fliq/services/fliq_api.dart';

import 'support/fake_fliq_api.dart';

void main() {
  setUp(() {
    FliqApi.instance = FakeFliqApi();
    AccountStore.instance = AccountStore();
  });

  testWidgets('pay link shows amount, link and closes the request flow', (
    tester,
  ) async {
    _usePhoneViewport(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute(builder: (_) => const RequestAmountScreen()),
            ),
            child: const Text('open request'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open request'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('amount-key-5')));
    await tester.tap(find.byKey(const ValueKey('amount-key-5')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('make-pay-link')));
    await tester.pumpAndSettle();

    expect(find.text('Waiting for payment'), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('pay-link-amount'))).data,
      '55.00',
    );
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('pay-link-url'))).data,
      startsWith('fliq.cash/pay/olayinka05/'),
    );
    expect(find.text('Copy link'), findsOneWidget);

    // Back keeps the request screen; close shuts both.
    await tester.tap(find.byKey(const ValueKey('pay-link-back')));
    await tester.pumpAndSettle();
    expect(find.byType(RequestAmountScreen), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('make-pay-link')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('pay-link-close')));
    await tester.pumpAndSettle();
    expect(find.byType(PayLinkScreen), findsNothing);
    expect(find.byType(RequestAmountScreen), findsNothing);
    expect(find.text('open request'), findsOneWidget);
  });

  testWidgets('home shows the recent card and opens its receipt', (
    tester,
  ) async {
    _usePhoneViewport(tester);
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

    expect(find.byKey(const ValueKey('recent-card')), findsOneWidget);
    expect(find.text('Received from Bitcoin'), findsOneWidget);
    expect(find.text('Not received'), findsOneWidget);

    await tester.tap(find.text('Received from Bitcoin'));
    await tester.pumpAndSettle();

    expect(find.text("Didn't go through"), findsOneWidget);
    expect(find.text('Deposit'), findsOneWidget);
    expect(find.text('Share receipt'), findsOneWidget);
  });

  testWidgets('activity tab filters transactions', (tester) async {
    _usePhoneViewport(tester);
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

    await tester.tap(find.byKey(const ValueKey('nav-activity')));
    await tester.pumpAndSettle();

    expect(find.text('Activity'), findsWidgets);
    expect(find.text('15 Nov 2026'), findsOneWidget);
    expect(find.text('Received from Bitcoin'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('activity-filter-agents')));
    await tester.pumpAndSettle();
    expect(find.text('Nothing yet'), findsOneWidget);
    expect(find.byKey(const ValueKey('activity-receive')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('nav-home')));
    await tester.pumpAndSettle();
    expect(find.text('Vault balance'), findsOneWidget);
  });

  testWidgets('home QR icon opens Receive Tokens and switches token', (
    tester,
  ) async {
    _usePhoneViewport(tester);
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

    await tester.tap(find.byKey(const ValueKey('qr-action')));
    await tester.pumpAndSettle();

    expect(find.byType(ReceiveTokensSheet), findsOneWidget);
    expect(
      find.text(
        'To avoid loss of funds, only send USDC on NEAR to this address.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('token-picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('BTC').last);
    await tester.pumpAndSettle();

    expect(
      find.text(
        'To avoid loss of funds, only send BTC on Bitcoin to this address.',
      ),
      findsOneWidget,
    );
    // Signed out, the sheet shows a demo address and says so.
    expect(find.byKey(const ValueKey('demo-address-warning')), findsOneWidget);
    await _reveal(tester, find.text('BITCOIN ADDRESS'));
    expect(find.text('BITCOIN ADDRESS'), findsOneWidget);
  });

  testWidgets('fliq name page shows the QR and NEAR address', (tester) async {
    _usePhoneViewport(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => FliqNamePage.show(context),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Your fliq name'), findsOneWidget);
    expect(find.text('@olayinka05'), findsOneWidget);
    expect(find.text('Copy NEAR address'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('sheet-close')));
    await tester.pumpAndSettle();
    expect(find.byType(FliqNamePage), findsNothing);
  });

  testWidgets('external wallet goes currency → network → address', (
    tester,
  ) async {
    _usePhoneViewport(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => ChooseCurrencyPage.show(context),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Choose currency to receive'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('currency-USDC')));
    await tester.pumpAndSettle();
    expect(find.text('Receive USDC'), findsOneWidget);
    expect(find.text('~2s · no fee'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('network-Monad')));
    await tester.pumpAndSettle();
    expect(find.text('Monad network'), findsOneWidget);
    expect(find.byKey(const ValueKey('demo-address-warning')), findsOneWidget);
    expect(find.text('0.10 USDC'), findsOneWidget);
    await _reveal(tester, find.byKey(const ValueKey('address-open-for')));
    // Counts down to when the address closes, as minutes:seconds.
    expect(find.textContaining(RegExp(r'^4,3(29|30):\d\d$')), findsOneWidget);

    // Back to the network list, then back to currencies, then Bitcoin,
    // which has one network and goes straight to its address.
    await tester.tap(find.byKey(const ValueKey('sheet-back')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('sheet-back')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('currency-BTC')));
    await tester.pumpAndSettle();
    expect(find.text('Receive BTC'), findsOneWidget);
    expect(find.text('USDC in your vault'), findsOneWidget);
  });

  testWidgets('NEAR deposit address does not expire', (tester) async {
    _usePhoneViewport(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => ChooseCurrencyPage.show(context),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('currency-USDC')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('network-NEAR')));
    await tester.pumpAndSettle();

    expect(find.text('0.01 USDC'), findsOneWidget);
    expect(find.byKey(const ValueKey('address-open-for')), findsNothing);
  });

  testWidgets('bank transfer deposit converts naira and checks contact', (
    tester,
  ) async {
    _usePhoneViewport(tester);
    await tester.pumpWidget(
      const MaterialApp(home: BankTransferDepositScreen()),
    );

    expect(find.text('Add money by bank transfer'), findsOneWidget);
    expect(find.text('You get about \$3.44 in your vault'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('deposit-preset-20000')));
    await tester.pump();
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('deposit-amount'))).data,
      '20,000',
    );

    await tester.tap(find.byKey(const ValueKey('deposit-key-delete')));
    await tester.pump();
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('deposit-amount'))).data,
      '2,000',
    );

    await tester.tap(find.byKey(const ValueKey('get-bank-details')));
    await tester.pumpAndSettle();
    expect(find.text("Confirm it's you"), findsOneWidget);

    OutlinedButton sendCode() =>
        tester.widget(find.byKey(const ValueKey('send-code')));
    expect(sendCode().onPressed, isNull);

    await tester.enterText(
      find.byKey(const ValueKey('deposit-contact')),
      'not-an-email',
    );
    await tester.pump();
    expect(sendCode().onPressed, isNull);

    await tester.enterText(
      find.byKey(const ValueKey('deposit-contact')),
      '+2348012345678',
    );
    await tester.pump();
    expect(sendCode().onPressed, isNotNull);

    // Back returns to the amount step, not out of the screen.
    await tester.tap(find.byKey(const ValueKey('bank-deposit-back')));
    await tester.pumpAndSettle();
    expect(find.text('Amount in naira'), findsOneWidget);
  });

  testWidgets('unknown fliq name shows a warning', (tester) async {
    _usePhoneViewport(tester);
    await tester.pumpWidget(const MaterialApp(home: FliqRecipientScreen()));

    await tester.enterText(
      find.byKey(const ValueKey('fliq-recipient-name')),
      'se',
    );
    await tester.pump();
    expect(find.text('No one on fliq has that name'), findsNothing);

    await tester.enterText(
      find.byKey(const ValueKey('fliq-recipient-name')),
      'seji',
    );
    // The name is looked up after a short pause in typing.
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    expect(find.text('No one on fliq has that name'), findsOneWidget);
  });

  testWidgets('settings opens live rates and money sheets', (tester) async {
    _usePhoneViewport(tester);
    await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));

    await _reveal(tester, find.text('Live rates, all providers'));
    await tester.tap(find.text('Live rates, all providers'));
    await tester.pumpAndSettle();
    expect(find.text('1,376.32'), findsOneWidget);
    expect(find.text('Best of 3 quoting · Paycrest'), findsOneWidget);
    expect(find.text('₦1,383.20'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('close-live-rates')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('How your money is held'));
    await tester.pumpAndSettle();
    expect(find.text('fliq-vault.near'), findsOneWidget);
  });

  testWidgets('sign out returns to the welcome screen', (tester) async {
    _usePhoneViewport(tester);
    await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));

    await _reveal(tester, find.text('Sign out'));
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    expect(find.text('Sign out of fliq on this phone?'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('confirm-sign-out')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(find.byType(SettingsScreen), findsNothing);
  });

  testWidgets('security lets you change when the app locks', (tester) async {
    _usePhoneViewport(tester);
    await tester.pumpWidget(const MaterialApp(home: SecuritySettingsScreen()));

    await _reveal(tester, find.byKey(const ValueKey('lock-delay')));
    expect(find.text('After 1 minute'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('lock-delay')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('After 5 minutes').last);
    await tester.pumpAndSettle();
    expect(find.text('After 5 minutes'), findsOneWidget);

    await _reveal(tester, find.text('Account backup'), delta: -200);
    await tester.tap(find.text('Account backup'));
    await tester.pumpAndSettle();
    expect(find.text("This phone isn't set up"), findsOneWidget);
  });

  testWidgets('connected agent shows its card and can be revoked', (
    tester,
  ) async {
    _usePhoneViewport(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: AgentsSettingsScreen(authenticator: _AlwaysAuthenticates()),
      ),
    );

    await tester.tap(find.text('Connect an agent'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('connect-agent-Claude')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('connect-agent-face-id')));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    expect(find.byKey(const ValueKey('agent-card-Claude')), findsOneWidget);
    expect(find.text('Connecting'), findsOneWidget);
    expect(
      find.textContaining('KES, NGN only', findRichText: true),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('agent-revoke')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('confirm-revoke')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('agent-card-Claude')), findsNothing);
  });
}

/// Scrolls the page until [finder] is built and fully on screen.
Future<void> _reveal(
  WidgetTester tester,
  Finder finder, {
  double delta = 200,
}) async {
  final scrollable = find.byType(Scrollable).first;
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(finder, delta, scrollable: scrollable);
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

void _usePhoneViewport(WidgetTester tester) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(393, 852);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

class _AlwaysAuthenticates implements BiometricAuthenticator {
  @override
  Future<bool> authenticate() async => true;
}
