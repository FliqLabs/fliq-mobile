import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fliq/models/agent.dart';
import 'package:fliq/near/device_key.dart';
import 'package:fliq/near/near_format.dart';
import 'package:fliq/near/near_rpc.dart';
import 'package:fliq/screens/settings/agents_settings_screen.dart';
import 'package:fliq/services/account_store.dart';
import 'package:fliq/services/agents.dart';
import 'package:fliq/services/biometric_authenticator.dart';
import 'package:fliq/services/fliq_api.dart';
import 'package:fliq/services/vault_signer.dart';

import 'support/fake_fliq_api.dart';

void main() {
  test('vault call arguments are signed with sorted keys', () {
    expect(
      canonicalJson({
        'b': 1,
        'a': {
          'd': 'x',
          'c': ['z', 'y'],
        },
      }),
      '{"a":{"c":["z","y"],"d":"x"},"b":1}',
    );
  });

  test(
    'an agent key carries its seed and public key for the connector',
    () async {
      final key = await AgentKey.generate();
      final secret = Base58.decode(key.secretKey.substring('ed25519:'.length))!;
      expect(secret, hasLength(64));
      expect(NearKey.encode(secret.sublist(32)), key.publicKey);
    },
  );

  test('the Claude setup is one terminal command', () {
    const setup = AgentSetup(
      app: AgentApp.claude,
      accountId: 'claude-frank.fliq.near',
      secretKey: 'ed25519:secret',
      apiUrl: 'https://api/v1',
      rpcUrl: 'https://rpc',
    );
    expect(setup.snippet, startsWith('claude mcp add fliq \\\n'));
    expect(
      setup.snippet,
      contains('--env FLIQ_AGENT_ID=claude-frank.fliq.near'),
    );
    expect(
      setup.snippet,
      contains('--env FLIQ_AGENT_PRIVATE_KEY=ed25519:secret'),
    );
    expect(setup.snippet, endsWith('-- npx -y @fliqlabs/mcp'));
  });

  testWidgets('connecting an agent signs its vault policy, then revoking it', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final api = FakeFliqApi(signedIn: true);
    FliqApi.instance = api;
    AccountStore.instance = AccountStore();
    await AccountStore.instance.start();
    await AccountStore.instance.ready;
    final keys = MemoryDeviceKeys(List.generate(32, (i) => i + 1));
    VaultSigner.instance = VaultSigner(
      keys: keys,
      rpcOverride: _FakeRpc(await keys.publicKey()),
      pollInterval: Duration.zero,
    );

    await tester.pumpWidget(
      MaterialApp(home: AgentsSettingsScreen(authenticator: _AlwaysYes())),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Connect an agent'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('connect-agent-Claude')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('connect-agent-face-id')));
    await tester.pumpAndSettle();

    // The agent's own fresh key went to the server; the phone signed
    // set_agent with sorted arguments.
    expect(api.connectedKeys.single, startsWith('ed25519:'));
    expect(keys.signatures, 1);
    final signed = utf8.decode(
      base64Decode(api.relayed.single),
      allowMalformed: true,
    );
    expect(signed, contains('set_agent'));
    expect(
      signed,
      contains(
        '{"agent_id":"claude-frank.fliq.near","corridors":["NG-NGN-bank"],'
        '"per_payout_cap":"36330000"}',
      ),
    );

    // The setup to paste, shown once.
    expect(find.byKey(const ValueKey('agent-setup-snippet')), findsOneWidget);
    expect(
      find.textContaining('FLIQ_AGENT_PRIVATE_KEY=ed25519:'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('agent-setup-done')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('agent-card-Claude')), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('agent-revoke')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('confirm-revoke')));
    await tester.pumpAndSettle();

    expect(keys.signatures, 2);
    expect(
      utf8.decode(base64Decode(api.relayed.last), allowMalformed: true),
      contains('remove_agent'),
    );
    expect(find.byKey(const ValueKey('agent-card-Claude')), findsNothing);
  });
}

class _AlwaysYes implements BiometricAuthenticator {
  @override
  Future<bool> authenticate() async => true;
}

class _FakeRpc extends NearRpc {
  _FakeRpc(this.publicKey);

  final String publicKey;

  @override
  Future<BigInt> accessKeyNonce(String account, String key) async =>
      BigInt.from(41);

  @override
  Future<BigInt> finalBlockHeight() async => BigInt.from(278837980);
}
