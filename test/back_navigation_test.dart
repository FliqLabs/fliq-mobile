import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fliq/screens/home_screen.dart';
import 'package:fliq/screens/pay_to_screen.dart';
import 'package:fliq/services/account_store.dart';
import 'package:fliq/services/fliq_api.dart';

import 'support/fake_fliq_api.dart';

/// Back returns to the menu you came from; ✕ goes Home. As on the iPhone.
void main() {
  setUp(() {
    FliqApi.instance = FakeFliqApi();
    AccountStore.instance = AccountStore();
  });

  Future<void> openHome(WidgetTester tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('nav-transfer')));
    await tester.pumpAndSettle();
  }

  const menu = 'What do you want to do?';

  testWidgets('Back from Send returns to the transfer menu', (tester) async {
    await openHome(tester);
    await tester.tap(find.byKey(const ValueKey('transfer-send')));
    await tester.pumpAndSettle();
    expect(find.byType(PayToScreen), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded).first);
    await tester.pumpAndSettle();
    expect(find.text(menu), findsOneWidget);
  });

  testWidgets('Close from Send goes Home', (tester) async {
    await openHome(tester);
    await tester.tap(find.byKey(const ValueKey('transfer-send')));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.close_rounded).first);
    await tester.pumpAndSettle();
    expect(find.text(menu), findsNothing);
    expect(find.byType(PayToScreen), findsNothing);
  });

  testWidgets('Back from Request returns to the transfer menu', (tester) async {
    await openHome(tester);
    await tester.tap(find.byKey(const ValueKey('transfer-request')));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded).first);
    await tester.pumpAndSettle();
    expect(find.text(menu), findsOneWidget);
  });

  testWidgets('Back walks Your fliq name → get paid → transfer menu', (
    tester,
  ) async {
    await openHome(tester);
    await tester.tap(find.byKey(const ValueKey('transfer-receive')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('receive-fliq-name')));
    await tester.pumpAndSettle();
    expect(find.text('Your fliq name'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('sheet-back')));
    await tester.pumpAndSettle();
    expect(find.text('How do you want to get paid?'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('receive-back')));
    await tester.pumpAndSettle();
    expect(find.text(menu), findsOneWidget);
  });

  testWidgets('Close from Your fliq name goes Home', (tester) async {
    await openHome(tester);
    await tester.tap(find.byKey(const ValueKey('transfer-receive')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('receive-fliq-name')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('sheet-close')));
    await tester.pumpAndSettle();
    expect(find.text('How do you want to get paid?'), findsNothing);
    expect(find.text(menu), findsNothing);
  });
}
