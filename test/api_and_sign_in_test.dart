import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:fliq/models/transaction.dart';
import 'package:fliq/screens/home_screen.dart';
import 'package:fliq/screens/sign_in_screen.dart';
import 'package:fliq/services/account_store.dart';
import 'package:fliq/services/api_exception.dart';
import 'package:fliq/services/fliq_api.dart';
import 'package:fliq/services/session_store.dart';

import 'support/fake_fliq_api.dart';

void main() {
  setUp(() {
    FliqApi.instance = FakeFliqApi();
    AccountStore.instance = AccountStore();
  });

  group('sign-in link', () {
    test('finds the token in a link, a fliq:// link or on its own', () {
      expect(
        SignInScreen.tokenIn('https://fliq.cash/auth/verify?token=el_abc'),
        'el_abc',
      );
      expect(SignInScreen.tokenIn('fliq://auth/verify?token=el_xyz'), 'el_xyz');
      expect(SignInScreen.tokenIn('  el_bare  '), 'el_bare');
      expect(SignInScreen.tokenIn('hello there'), isNull);
    });
  });

  testWidgets('email sign-in sends a link, then signs in with it', (
    tester,
  ) async {
    final api = FakeFliqApi();
    FliqApi.instance = api;
    await tester.pumpWidget(const MaterialApp(home: SignInScreen()));

    await tester.enterText(
      find.byKey(const ValueKey('sign-in-email')),
      'frank@example.com',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('send-sign-in-link')));
    await tester.pumpAndSettle();

    expect(api.sentLinksTo, ['frank@example.com']);
    expect(find.text('Check your email'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('sign-in-link')),
      'https://fliq.cash/auth/verify?token=el_expired',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('verify-sign-in-link')));
    await tester.pumpAndSettle();
    expect(
      find.text('This link has expired or was already used. Send a new one.'),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const ValueKey('sign-in-link')),
      'https://fliq.cash/auth/verify?token=${FakeFliqApi.goodToken}',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('verify-sign-in-link')));
    await tester.pumpAndSettle();

    expect(AccountStore.instance.isSignedIn, isTrue);
    expect(AccountStore.instance.handle, 'frank');
    expect(AccountStore.instance.balanceUsd, 128.18);
  });

  testWidgets('signed-in home shows the real balance and activity', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    FliqApi.instance = FakeFliqApi(signedIn: true);
    await AccountStore.instance.start();
    await AccountStore.instance.ready;

    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('vault-balance-amount')))
          .data,
      '128',
    );
    expect(find.text('DARA OKONKWO'), findsOneWidget);
    expect(find.text('₦68,816'), findsOneWidget);
    expect(find.text('Paid'), findsOneWidget);
  });

  group('activity items', () {
    test('a payout reads like the iPhone app', () {
      final item = Transaction.fromActivity(const {
        'activity_id': 'act_po_9c2f71aa',
        'kind': 'payout',
        'status': 'paid',
        'at': '2026-10-29T13:02:32Z',
        'party': {'name': 'DARA OKONKWO', 'account_last4': '6789'},
        'provider': 'paycrest',
        'agent': null,
        'local': {'amount': '68816', 'currency': 'NGN'},
        'usd': '50.00',
        'ref_id': 'po_9c2f71aa',
      });
      expect(item.title, 'DARA OKONKWO');
      expect(item.amount, '₦68,816');
      expect(item.statusLabel, 'Paid');
      expect(item.category, 'Cash out');
      expect(item.source, TransactionSource.mine);
      expect(item.facts, contains(('Paid out by', 'Paycrest')));
      expect(item.facts, contains(('Account', '•••• 6789')));
    });

    test('a deposit and an agent refusal', () {
      final deposit = Transaction.fromActivity(const {
        'kind': 'deposit',
        'status': 'received',
        'at': '2026-10-29T08:12:14Z',
        'party': {'name': 'Received from Solana'},
        'usd': '199.98',
        'token': '200 USDC',
        'ref_id': 'dep_01',
      });
      expect(deposit.amount, '200 USDC');
      expect(deposit.statusLabel, 'Received');
      expect(deposit.network, 'Solana');
      expect(deposit.source, TransactionSource.external);

      final refused = Transaction.fromActivity(const {
        'kind': 'refused',
        'status': 'refused',
        'at': '2026-10-29T12:41:00Z',
        'party': {'name': 'DARA OKONKWO'},
        'agent': {'agent_id': 'claude-frank.fliq.near', 'name': 'Claude'},
        'local': {'amount': '500000', 'currency': 'NGN'},
        'reason': 'over_daily_cap',
        'ref_id': 'ref_01',
      });
      expect(refused.title, 'Claude asked to pay DARA OKONKWO');
      expect(refused.statusLabel, 'Refused');
      expect(refused.source, TransactionSource.agent);
      expect(refused.facts, contains(('Why', 'Over its daily limit')));
    });
  });

  group('session renewal', () {
    SessionTokens tokens({required Duration expiresIn}) => SessionTokens(
      accessToken: 'at_old',
      refreshToken: 'rf_old',
      expiresAt: DateTime.now().add(expiresIn),
    );

    Map<String, dynamic> session(String access) => {
      'access_token': access,
      'refresh_token': 'rf_new',
      'expires_in': 900,
      'user': {
        'user_id': 'usr_1',
        'near_account': 'frank.fliq.near',
        'display_name': 'Frank',
        'photo_url': null,
        'occupation': null,
        'vault': 'fliq-vault.testnet',
      },
    };

    final meJson = jsonEncode(session('x')['user']);

    test('renews once on a 401 and retries with the new token', () async {
      final seen = <String>[];
      var refreshes = 0;
      final client = MockClient((request) async {
        if (request.url.path.endsWith('/auth/refresh')) {
          refreshes++;
          expect(jsonDecode(request.body), {'refresh_token': 'rf_old'});
          return http.Response(jsonEncode(session('at_new')), 200);
        }
        seen.add(request.headers['Authorization']!);
        return request.headers['Authorization'] == 'Bearer at_new'
            ? http.Response(meJson, 200)
            : http.Response('{"error":{"code":"unauthorized"}}', 401);
      });
      final store = MemorySessionStore(
        tokens(expiresIn: const Duration(hours: 1)),
      );
      final api = FliqApi(
        client: client,
        sessions: store,
        baseUrl: 'https://x/v1',
      );

      final user = await api.me();

      expect(user.handle, 'frank');
      expect(seen, ['Bearer at_old', 'Bearer at_new']);
      expect(refreshes, 1);
      expect((await store.read())!.refreshToken, 'rf_new');
    });

    test('renews ahead of time when the token is about to expire', () async {
      final client = MockClient((request) async {
        if (request.url.path.endsWith('/auth/refresh')) {
          return http.Response(jsonEncode(session('at_new')), 200);
        }
        expect(request.headers['Authorization'], 'Bearer at_new');
        return http.Response(meJson, 200);
      });
      final api = FliqApi(
        client: client,
        sessions: MemorySessionStore(
          tokens(expiresIn: const Duration(seconds: 10)),
        ),
        baseUrl: 'https://x/v1',
      );
      await api.me();
    });

    test('a refused refresh token ends the session', () async {
      var ended = false;
      final client = MockClient(
        (request) async => http.Response(
          '{"error":{"code":"unauthorized","message":"no"}}',
          401,
        ),
      );
      final store = MemorySessionStore(
        tokens(expiresIn: const Duration(hours: 1)),
      );
      final api = FliqApi(
        client: client,
        sessions: store,
        baseUrl: 'https://x/v1',
      )..onSignedOut = () => ended = true;

      await expectLater(
        api.me(),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 401)),
      );
      expect(ended, isTrue);
      expect(await store.read(), isNull);
    });

    test('server errors come back as readable ApiExceptions', () async {
      final client = MockClient(
        (request) async => http.Response(
          '{"error":{"code":"invalid_request","message":"Unsupported token USDC."}}',
          400,
        ),
      );
      final api = FliqApi(
        client: client,
        sessions: MemorySessionStore(),
        baseUrl: 'https://x/v1',
      );
      await expectLater(
        api.getRate(token: 'USDC'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.code, 'code', 'invalid_request')
              .having((e) => e.message, 'message', 'Unsupported token USDC.'),
        ),
      );
    });
  });
}
