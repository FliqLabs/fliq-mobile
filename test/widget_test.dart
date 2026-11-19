import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fliq/app.dart';
import 'package:fliq/screens/home_screen.dart';
import 'package:fliq/screens/new_recipient_screen.dart';
import 'package:fliq/screens/pay_to_screen.dart';
import 'package:fliq/screens/qr_scanner_screen.dart';
import 'package:fliq/screens/recipient_flow_screens.dart';
import 'package:fliq/screens/request_amount_screen.dart';
import 'package:fliq/screens/send_amount_screen.dart';
import 'package:fliq/screens/settings/accounts_settings_screen.dart';
import 'package:fliq/screens/settings/agents_settings_screen.dart';
import 'package:fliq/screens/settings/daily_limit_screen.dart';
import 'package:fliq/screens/settings/settings_screen.dart';
import 'package:fliq/services/biometric_authenticator.dart';
import 'package:fliq/widgets/fliq_logo.dart';

void main() {
  testWidgets('welcome screen shows its copy and account actions', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const FliqApp());

    expect(find.text('Money without\nborders'), findsOneWidget);
    expect(
      find.text(
        'Any chain. Any bank or mobile money.\nBest live rates, in seconds.',
      ),
      findsOneWidget,
    );
    expect(find.text('Continue with passkey'), findsOneWidget);
    expect(find.text('I already have an account'), findsOneWidget);
    expect(find.byType(FliqLogo), findsOneWidget);

    await tester.tap(find.text('Continue with passkey'));
    await tester.pump();
    expect(
      find.text('Passkey sign-up will be available soon.'),
      findsOneWidget,
    );
  });

  testWidgets('existing account opens biometric unlock', (
    WidgetTester tester,
  ) async {
    final authenticator = _FakeBiometricAuthenticator();
    await tester.pumpWidget(FliqApp(biometricAuthenticator: authenticator));

    await tester.tap(find.text('I already have an account'));
    await tester.pumpAndSettle();

    expect(find.text('fliq is locked'), findsOneWidget);
    expect(find.byKey(const ValueKey('biometric-unlock')), findsOneWidget);
    final wordmark = tester.widget<Text>(
      find.byKey(const ValueKey('fliq-wordmark')),
    );
    expect(wordmark.data, 'flıq');
    expect(wordmark.semanticsLabel, 'fliq');
    expect(find.byKey(const ValueKey('fliq-wordmark-dot')), findsOneWidget);
    final paragraph = tester.renderObject<RenderParagraph>(
      find.descendant(
        of: find.byKey(const ValueKey('fliq-wordmark')),
        matching: find.byType(RichText),
      ),
    );
    final iBounds = paragraph
        .getBoxesForSelection(
          const TextSelection(baseOffset: 2, extentOffset: 3),
        )
        .single;
    final iCenter = paragraph
        .localToGlobal(Offset((iBounds.left + iBounds.right) / 2, 0))
        .dx;
    final dotCenter = tester
        .getCenter(find.byKey(const ValueKey('fliq-wordmark-dot')))
        .dx;
    expect(dotCenter, closeTo(iCenter - 1.5, 0.01));

    await tester.tap(find.byKey(const ValueKey('biometric-unlock')));
    await tester.pumpAndSettle();

    expect(authenticator.authenticateCalls, 1);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Vault balance'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('home screen hides and shows the vault balance', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

    expect(find.text('0'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('toggle-balance')));
    await tester.pump();

    expect(find.text('••••'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('toggle-balance')));
    await tester.pump();

    expect(find.text('0'), findsOneWidget);
    expect(find.byKey(const ValueKey('exchange-quote')), findsOneWidget);
  });

  testWidgets('profile action opens settings and notification preferences', (
    WidgetTester tester,
  ) async {
    _usePhoneViewport(tester);
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

    await tester.tap(find.byKey(const ValueKey('profile-action')));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(find.text('Your profile'), findsOneWidget);
    expect(find.text('Your daily limit'), findsOneWidget);

    await tester.tap(find.text('Notifications'));
    await tester.pumpAndSettle();
    expect(find.text('Received in your vault'), findsOneWidget);
    final notificationSwitch = find.byKey(
      const ValueKey('notification-Received in your vault'),
    );
    expect(tester.widget<Switch>(notificationSwitch).value, isTrue);
    await tester.tap(notificationSwitch);
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(notificationSwitch).value, isFalse);

    await tester.tap(find.byKey(const ValueKey('settings-back')));
    await tester.pumpAndSettle();
    final dailyLimit = find.text('Your daily limit');
    await tester.ensureVisible(dailyLimit);
    await tester.tap(dailyLimit);
    await tester.pumpAndSettle();
    expect(find.text('No daily limit'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('set-daily-limit')));
    await tester.pumpAndSettle();
    expect(find.text('A day'), findsOneWidget);
    expect(find.text('Save with biometrics'), findsOneWidget);
    expect(find.byKey(const ValueKey('daily-key-1')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('daily-key-1')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('daily-limit-amount')))
          .data,
      '1',
    );
    await tester.tap(find.byKey(const ValueKey('cancel-daily-limit')));
    await tester.pumpAndSettle();
    expect(find.text('No daily limit'), findsOneWidget);
  });

  testWidgets('settings profile opens the edit avatar sheet', (
    WidgetTester tester,
  ) async {
    _usePhoneViewport(tester);
    await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));

    final backButtonRect = tester.getRect(
      find.byKey(const ValueKey('settings-back')),
    );
    final titleRect = tester.getRect(find.text('Settings'));
    expect(backButtonRect.right, lessThan(titleRect.left));

    await tester.tap(find.byKey(const ValueKey('settings-profile')));
    await tester.pumpAndSettle();

    expect(find.text('Edit avatar'), findsOneWidget);
    expect(find.text('@olayinka05'), findsNWidgets(2));
    expect(find.byKey(const ValueKey('add-avatar-photo')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('close-avatar-sheet')));
    await tester.pumpAndSettle();
    expect(find.text('Edit avatar'), findsNothing);
  });

  testWidgets('daily limit keypad saves a positive amount with biometrics', (
    WidgetTester tester,
  ) async {
    final authenticator = _FakeBiometricAuthenticator();
    _usePhoneViewport(tester);
    await tester.pumpWidget(
      MaterialApp(home: DailyLimitScreen(authenticator: authenticator)),
    );

    await tester.tap(find.byKey(const ValueKey('set-daily-limit')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<OutlinedButton>(
            find.byKey(const ValueKey('save-daily-limit')),
          )
          .onPressed,
      isNull,
    );

    await tester.tap(find.byKey(const ValueKey('daily-key-1')));
    await tester.tap(find.byKey(const ValueKey('daily-key-2')));
    await tester.tap(find.byKey(const ValueKey('daily-key-3')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('daily-limit-amount')))
          .data,
      '123',
    );
    await tester.tap(find.byKey(const ValueKey('daily-key-delete')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('daily-limit-amount')))
          .data,
      '12',
    );
    await tester.tap(find.byKey(const ValueKey('daily-key-3')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('save-daily-limit')));
    await tester.pumpAndSettle();
    expect(authenticator.authenticateCalls, 1);
    expect(find.text('\$123 per day'), findsOneWidget);
  });

  testWidgets('new account validates an account number before continuing', (
    WidgetTester tester,
  ) async {
    _usePhoneViewport(tester);
    await tester.pumpWidget(const MaterialApp(home: AccountsSettingsScreen()));

    await tester.tap(find.byKey(const ValueKey('add-account')));
    await tester.pumpAndSettle();
    expect(find.text('New account'), findsOneWidget);
    expect(find.text('GTBank'), findsOneWidget);

    final continueButton = tester.widget<OutlinedButton>(
      find.byKey(const ValueKey('continue-new-account')),
    );
    expect(continueButton.onPressed, isNull);

    await tester.tap(find.byKey(const ValueKey('account-bank-picker')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('bank-search')),
      'Moniepoint',
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('bank-option-Moniepoint')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('bank-option-Moniepoint')));
    await tester.pumpAndSettle();
    expect(find.text('Moniepoint'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('country-kenya')));
    await tester.pumpAndSettle();
    expect(find.text('Equity Bank'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('account-bank-picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('bank-option-KCB')));
    await tester.pumpAndSettle();
    expect(find.text('KCB'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('new-account-number')),
      '1234567890',
    );
    await tester.pumpAndSettle();
    expect(find.text('10/14'), findsOneWidget);
    expect(
      tester
          .widget<OutlinedButton>(
            find.byKey(const ValueKey('continue-new-account')),
          )
          .onPressed,
      isNotNull,
    );

    await tester.tap(find.byKey(const ValueKey('continue-new-account')));
    await tester.pumpAndSettle();
    expect(find.text('KCB\n1234567890'), findsOneWidget);
  });

  testWidgets('agent setup configures limits and requires biometric auth', (
    WidgetTester tester,
  ) async {
    final authenticator = _FakeBiometricAuthenticator();
    _usePhoneViewport(tester);
    await tester.pumpWidget(
      MaterialApp(home: AgentsSettingsScreen(authenticator: authenticator)),
    );

    await tester.tap(find.text('Connect an agent'));
    await tester.pumpAndSettle();
    expect(find.text('Which app is your agent in?'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('connect-agent-Claude')));
    await tester.pumpAndSettle();

    expect(find.text('Claude'), findsNWidgets(2));
    expect(find.text('₦30,000'), findsOneWidget);
    expect(find.text('₦15,000'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('agent-daily-limit-increase')));
    await tester.pumpAndSettle();
    expect(find.text('₦35,000'), findsOneWidget);
    expect(find.textContaining('₦35,000 a day'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('agent-country-kenya')));
    await tester.pumpAndSettle();
    expect(find.textContaining('to bank accounts in Nigeria,'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('connect-agent-face-id')));
    await tester.pumpAndSettle();
    expect(authenticator.authenticateCalls, 1);
    expect(find.text('Connecting'), findsOneWidget);
  });

  testWidgets('transfer send opens recipient selection screen', (
    WidgetTester tester,
  ) async {
    _usePhoneViewport(tester);
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

    await tester.tap(find.byKey(const ValueKey('nav-transfer')));
    await tester.pumpAndSettle();

    expect(find.text('What do you want to do?'), findsOneWidget);
    expect(find.text('Bank, mobile money or fliq'), findsOneWidget);
    expect(find.text('Your name, or any coin'), findsOneWidget);
    expect(find.text('A link anyone can pay'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('transfer-send')));
    await tester.pumpAndSettle();

    expect(find.text('What do you want to do?'), findsNothing);
    expect(find.byType(PayToScreen), findsOneWidget);
    expect(find.text('Pay to'), findsOneWidget);
    expect(find.text('Scan to pay'), findsOneWidget);
    expect(find.text('Send to a wallet'), findsOneWidget);
    _expectHeaderButtonsAtOppositeEnds(
      tester,
      find.byIcon(Icons.arrow_back_ios_new_rounded),
      find.byIcon(Icons.close_rounded),
    );
  });

  testWidgets('transfer receive opens receive options', (
    WidgetTester tester,
  ) async {
    _usePhoneViewport(tester);
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

    await tester.tap(find.byKey(const ValueKey('nav-transfer')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('transfer-receive')));
    await tester.pumpAndSettle();

    expect(find.text('What do you want to do?'), findsNothing);
    expect(find.text('How do you want to get paid?'), findsOneWidget);
    expect(find.text('Bank transfer'), findsOneWidget);
    expect(find.text('Your fliq name'), findsOneWidget);
    expect(find.text('External wallet'), findsOneWidget);
    expect(find.byKey(const ValueKey('receive-fliq-symbol')), findsOneWidget);
    expect(find.byKey(const ValueKey('receive-bank-transfer')), findsOneWidget);
    expect(find.byKey(const ValueKey('receive-fliq-name')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('receive-external-wallet')),
      findsOneWidget,
    );
  });

  testWidgets('scan to pay opens QR scanner screen', (
    WidgetTester tester,
  ) async {
    _usePhoneViewport(tester);
    await tester.pumpWidget(const MaterialApp(home: PayToScreen()));
    await tester.tap(find.byKey(const ValueKey('scan-to-pay')));
    await tester.pumpAndSettle();

    expect(find.byType(QrScannerScreen), findsOneWidget);
    expect(
      find.text('Point at a bank QR code or an\naccount number'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('qr-scan-window')), findsOneWidget);
  });

  testWidgets('new recipient opens currency selection screen', (
    WidgetTester tester,
  ) async {
    _usePhoneViewport(tester);
    await tester.pumpWidget(const MaterialApp(home: PayToScreen()));

    await tester.tap(find.byKey(const ValueKey('new-recipient')));
    await tester.pumpAndSettle();

    expect(find.byType(SendAmountScreen), findsNothing);
    expect(find.byType(NewRecipientScreen), findsOneWidget);
    expect(find.text('What currency should\nthey receive?'), findsOneWidget);
    expect(find.text('Available now'), findsOneWidget);
    expect(find.text('Naira'), findsOneWidget);
    expect(find.text('Kenyan Shilling'), findsOneWidget);
    expect(find.text('Stablecoin'), findsOneWidget);
    expect(find.text('USD Coin, to a NEAR wallet'), findsOneWidget);
    expect(find.text('Brazilian Real'), findsOneWidget);
    expect(find.text('Soon'), findsWidgets);
  });

  testWidgets('currency search filters the recipient list', (
    WidgetTester tester,
  ) async {
    _usePhoneViewport(tester);
    await tester.pumpWidget(const MaterialApp(home: NewRecipientScreen()));

    await tester.enterText(
      find.byKey(const ValueKey('currency-search')),
      'Kenyan',
    );
    await tester.pumpAndSettle();

    expect(find.text('Kenyan Shilling'), findsOneWidget);
    expect(find.text('Naira'), findsNothing);
    expect(find.text('USD Coin, to a NEAR wallet'), findsNothing);
    expect(find.text('No currencies found'), findsNothing);
  });

  testWidgets('currency search also matches country names', (
    WidgetTester tester,
  ) async {
    _usePhoneViewport(tester);
    await tester.pumpWidget(const MaterialApp(home: NewRecipientScreen()));

    await tester.enterText(
      find.byKey(const ValueKey('currency-search')),
      'Nigeria',
    );
    await tester.pumpAndSettle();

    expect(find.text('Naira'), findsOneWidget);
    expect(find.text('Kenyan Shilling'), findsNothing);
  });

  testWidgets('Naira opens bank and fliq delivery choices', (
    WidgetTester tester,
  ) async {
    _usePhoneViewport(tester);
    await tester.pumpWidget(const MaterialApp(home: NewRecipientScreen()));

    await tester.tap(find.byKey(const ValueKey('currency-NGN (N)')));
    await tester.pumpAndSettle();

    expect(find.text('How do you want to\nsend NGN?'), findsOneWidget);
    expect(find.text('Bank transfer'), findsOneWidget);
    expect(find.text('fliq name'), findsOneWidget);
    expect(find.byKey(const ValueKey('send-fliq-name-symbol')), findsOneWidget);
    expect(find.text('Mobile money'), findsNothing);
  });

  testWidgets('Pay to filters show wallet only under All', (
    WidgetTester tester,
  ) async {
    _usePhoneViewport(tester);
    await tester.pumpWidget(const MaterialApp(home: PayToScreen()));

    expect(find.byKey(const ValueKey('send-to-wallet')), findsOneWidget);
    for (final index in [1, 2, 3]) {
      final filter = find.byKey(ValueKey('recipient-filter-$index'));
      await tester.ensureVisible(filter);
      await tester.tap(filter);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('scan-to-pay')), findsOneWidget);
      expect(find.byKey(const ValueKey('send-to-wallet')), findsNothing);
      if (index == 3) {
        expect(
          find.byKey(const ValueKey('fliq-user-filter-symbol')),
          findsOneWidget,
        );
      }
    }

    expect(find.text('No fliq users yet'), findsOneWidget);
    expect(
      find.text('Search a fliq name to pay someone instantly, with no fee.'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.people_outline_rounded), findsOneWidget);
  });

  testWidgets('bank transfer requires a full account number', (
    WidgetTester tester,
  ) async {
    _usePhoneViewport(tester);
    await tester.pumpWidget(const MaterialApp(home: NewRecipientScreen()));

    await tester.tap(find.byKey(const ValueKey('currency-NGN (N)')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('delivery-method-bankTransfer')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(RecipientDetailsScreen), findsOneWidget);
    expect(find.text('Nigeria'), findsOneWidget);
    expect(find.text('GTBank'), findsOneWidget);
    expect(
      tester
          .widget<OutlinedButton>(
            find.byKey(const ValueKey('recipient-continue')),
          )
          .onPressed,
      isNull,
    );

    await tester.enterText(
      find.byKey(const ValueKey('recipient-account-number')),
      '0123456789',
    );
    await tester.pump();

    expect(
      tester
          .widget<OutlinedButton>(
            find.byKey(const ValueKey('recipient-continue')),
          )
          .onPressed,
      isNotNull,
    );

    await tester.tap(find.byKey(const ValueKey('recipient-continue')));
    await tester.pumpAndSettle();
    expect(find.byType(SendAmountScreen), findsOneWidget);
  });

  testWidgets('Kenyan shilling offers mobile money provider form', (
    WidgetTester tester,
  ) async {
    _usePhoneViewport(tester);
    await tester.pumpWidget(const MaterialApp(home: NewRecipientScreen()));

    await tester.tap(find.byKey(const ValueKey('currency-KES (KSh)')));
    await tester.pumpAndSettle();

    expect(find.text('How do you want to\nsend KES?'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('delivery-method-mobileMoney')));
    await tester.pumpAndSettle();

    expect(find.text('Kenya'), findsOneWidget);
    expect(find.text('Mobile money provider'), findsOneWidget);
    expect(find.text('Choose'), findsOneWidget);
    expect(find.text('Phone number'), findsOneWidget);
  });

  testWidgets('fliq name opens the pay-a-fliq-user screen', (
    WidgetTester tester,
  ) async {
    _usePhoneViewport(tester);
    await tester.pumpWidget(const MaterialApp(home: NewRecipientScreen()));

    await tester.tap(find.byKey(const ValueKey('currency-NGN (N)')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('delivery-method-fliqName')));
    await tester.pumpAndSettle();

    expect(find.byType(FliqRecipientScreen), findsOneWidget);
    expect(find.text('Pay a fliq user'), findsOneWidget);
    expect(find.byKey(const ValueKey('fliq-recipient-name')), findsOneWidget);
    expect(find.text('ϟ  Vault to vault · instant · no fee'), findsOneWidget);
    expect(find.byKey(const ValueKey('fliq-amount-keypad')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('fliq-amount-key-5')));
    await tester.pump();
    final amountText = tester.widget<Text>(
      find.byKey(const ValueKey('fliq-recipient-amount')),
    );
    expect(amountText.textSpan!.toPlainText(), '\$5');
  });

  testWidgets('send to a wallet opens send amount entry', (
    WidgetTester tester,
  ) async {
    _usePhoneViewport(tester);
    await tester.pumpWidget(const MaterialApp(home: PayToScreen()));

    await tester.tap(find.byKey(const ValueKey('send-to-wallet')));
    await tester.pumpAndSettle();

    expect(find.byType(SendAmountScreen), findsOneWidget);
    expect(find.text('Send'), findsOneWidget);
    expect(find.text('Vault'), findsOneWidget);
    expect(
      tester
          .widget<OutlinedButton>(find.byKey(const ValueKey('send-next')))
          .onPressed,
      isNull,
    );

    await tester.tap(find.byKey(const ValueKey('send-key-5')));
    await tester.pump();

    expect(
      tester.widget<Text>(find.byKey(const ValueKey('send-amount'))).data,
      '5',
    );
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('send-amount-usdc'))).data,
      '5.00  USDC',
    );
    // The sample vault holds $0, so $5 is more than the vault and Next
    // stays disabled, like the iPhone app.
    expect(find.text('More than your vault'), findsOneWidget);
    expect(
      tester
          .widget<OutlinedButton>(find.byKey(const ValueKey('send-next')))
          .onPressed,
      isNull,
    );
  });

  testWidgets('transfer request opens amount entry screen', (
    WidgetTester tester,
  ) async {
    _usePhoneViewport(tester);
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

    await tester.tap(find.byKey(const ValueKey('nav-transfer')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('transfer-request')));
    await tester.pumpAndSettle();

    expect(find.byType(RequestAmountScreen), findsOneWidget);
    expect(find.text('You ask for'), findsOneWidget);
    _expectHeaderButtonsAtOppositeEnds(
      tester,
      find.byIcon(Icons.arrow_back_ios_new_rounded),
      find.byIcon(Icons.close_rounded),
    );
    expect(find.text("What's it for?"), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('request-reason'))).width,
      closeTo(353 * 0.8, 1),
    );
    expect(find.text('Cash out to my bank when it lands'), findsOneWidget);
    final initialSwitch = tester.widget<Switch>(
      find.byKey(const ValueKey('cash-out-toggle')),
    );
    expect(initialSwitch.activeTrackColor, const Color(0xFF737373));
    expect(initialSwitch.activeThumbColor, Colors.white);

    await tester.tap(find.byKey(const ValueKey('cash-out-toggle')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<Switch>(find.byKey(const ValueKey('cash-out-toggle')))
          .value,
      isTrue,
    );

    expect(
      tester
          .widget<OutlinedButton>(find.byKey(const ValueKey('make-pay-link')))
          .onPressed,
      isNull,
    );

    await tester.tap(find.byKey(const ValueKey('amount-key-5')));
    await tester.pump();

    expect(
      tester.widget<Text>(find.byKey(const ValueKey('request-amount'))).data,
      '5',
    );
    expect(
      tester
          .widget<OutlinedButton>(find.byKey(const ValueKey('make-pay-link')))
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('request amount keypad supports decimals and delete', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: RequestAmountScreen()));

    await tester.tap(find.byKey(const ValueKey('amount-key-1')));
    await tester.tap(find.byKey(const ValueKey('amount-key-.')));
    await tester.tap(find.byKey(const ValueKey('amount-key-2')));
    await tester.pump();

    expect(find.text('1.2'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('amount-key-delete')));
    await tester.pump();
    expect(find.text('1.'), findsOneWidget);
  });
}

void _usePhoneViewport(WidgetTester tester) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(393, 852);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

void _expectHeaderButtonsAtOppositeEnds(
  WidgetTester tester,
  Finder backButton,
  Finder closeButton,
) {
  final backRect = tester.getRect(backButton);
  final closeRect = tester.getRect(closeButton);

  expect(backRect.right, lessThan(closeRect.left));
  expect(backRect.center.dy, closeRect.center.dy);
}

class _FakeBiometricAuthenticator implements BiometricAuthenticator {
  int authenticateCalls = 0;

  @override
  Future<bool> authenticate() async {
    authenticateCalls++;
    return true;
  }
}
