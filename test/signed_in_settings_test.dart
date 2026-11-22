import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fliq/models/account_models.dart';
import 'package:fliq/screens/settings/accounts_settings_screen.dart';
import 'package:fliq/screens/settings/daily_limit_screen.dart';
import 'package:fliq/screens/settings/notification_settings_screen.dart';
import 'package:fliq/screens/settings/security_settings_screen.dart';
import 'package:fliq/screens/settings/settings_screen.dart';
import 'package:fliq/services/account_store.dart';
import 'package:fliq/services/biometric_authenticator.dart';
import 'package:fliq/services/fliq_api.dart';

import 'support/fake_fliq_api.dart';

void main() {
  late FakeFliqApi api;

  setUp(() async {
    api = FakeFliqApi(signedIn: true);
    FliqApi.instance = api;
    AccountStore.instance = AccountStore();
    await AccountStore.instance.start();
    await AccountStore.instance.ready;
  });

  void usePhone(WidgetTester tester) {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets('settings rows show the account, limit and devices', (
    tester,
  ) async {
    usePhone(tester);
    api.currentLimits = const Limits(dailyLimit: 500);
    api.recipientsList.add(
      const Recipient(
        id: 'rcp_own',
        accountName: 'FRANK',
        bankName: 'Access Bank',
        last4: '4321',
        own: true,
      ),
    );

    await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Access Bank •••• 4321'), findsOneWidget);
    expect(find.text(r'$500 a day'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('2 signed in'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('2 signed in'), findsOneWidget);
  });

  testWidgets('saved accounts load, and a new one is checked and saved', (
    tester,
  ) async {
    usePhone(tester);
    await tester.pumpWidget(const MaterialApp(home: AccountsSettingsScreen()));
    await tester.pumpAndSettle();

    // DARA is a saved account someone was paid, so it is under SAVED.
    expect(find.text('DARA OKONKWO\nGTBank •••• 6789'), findsOneWidget);
    expect(
      find.text('Add your own account so cashing out is one tap.'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('add-account')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('new-account-number')),
      '0000000000',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('continue-new-account')));
    await tester.pumpAndSettle();
    expect(
      find.text("The bank couldn't find that account. Check the number."),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const ValueKey('new-account-number')),
      '0123456789',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('continue-new-account')));
    await tester.pumpAndSettle();

    expect(find.text('FRANK OKAFOR\nGTBank •••• 6789'), findsOneWidget);
  });

  testWidgets('a raised daily limit waits 24 hours', (tester) async {
    usePhone(tester);
    api.currentLimits = const Limits(dailyLimit: 100);
    await tester.pumpWidget(
      MaterialApp(home: DailyLimitScreen(authenticator: _AlwaysYes())),
    );
    await tester.pumpAndSettle();
    expect(find.text(r'$100 per day'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('set-daily-limit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('daily-key-5')));
    await tester.tap(find.byKey(const ValueKey('daily-key-0')));
    await tester.tap(find.byKey(const ValueKey('daily-key-0')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('save-daily-limit')));
    await tester.pumpAndSettle();

    expect(api.currentLimits.pendingLimit, 500);
    expect(find.byKey(const ValueKey('daily-limit-pending')), findsOneWidget);
  });

  testWidgets('other devices can be signed out', (tester) async {
    usePhone(tester);
    await tester.pumpWidget(const MaterialApp(home: DevicesSettingsScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Pixel 9\nThis device · active now'), findsOneWidget);
    expect(
      find.text('MacBook Pro · Safari\nactive 2 days ago'),
      findsOneWidget,
    );

    await tester.tap(find.text('Sign out').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign out').last);
    await tester.pumpAndSettle();

    expect(api.revokedSessions, ['ses_mac']);
    expect(find.textContaining('MacBook'), findsNothing);
  });

  testWidgets('notification switches save to the server', (tester) async {
    usePhone(tester);
    await tester.pumpWidget(
      const MaterialApp(home: NotificationSettingsScreen()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('notification-Weekly summary')));
    await tester.pumpAndSettle();

    expect(api.notifications['weekly_summary'], isTrue);
    expect(
      (api.notifications['rate_alert'] as Map)['above'],
      1400,
      reason: 'the rate alert threshold is kept',
    );
  });
}

class _AlwaysYes implements BiometricAuthenticator {
  @override
  Future<bool> authenticate() async => true;
}
