import 'package:cryptography/cryptography.dart';

import '../config/api_config.dart';
import '../models/agent.dart';
import '../near/delegate_action.dart';
import '../near/near_format.dart';
import 'account_store.dart';
import 'fliq_api.dart';
import 'payouts.dart';
import 'vault_signer.dart';

/// The limits an agent must stay within, in whole local units.
class AgentPolicy {
  const AgentPolicy({
    required this.dailyCap,
    required this.perPayout,
    required this.paysNigeria,
    required this.paysKenya,
    required this.savedAccountsOnly,
  });

  final int dailyCap;
  final int perPayout;
  final bool paysNigeria;
  final bool paysKenya;
  final bool savedAccountsOnly;

  /// The body the API takes. Caps are in naira when the agent may pay in
  /// naira, otherwise in shillings, as the iPhone app sends them.
  Map<String, dynamic> toJson() {
    final currency = paysNigeria || !paysKenya ? 'NGN' : 'KES';
    return {
      'daily_cap': {'amount': '$dailyCap', 'currency': currency},
      'per_payout_cap': {'amount': '$perPayout', 'currency': currency},
      'currencies': [if (paysKenya) 'KES', if (paysNigeria) 'NGN'],
      'saved_accounts_only': savedAccountsOnly,
    };
  }
}

/// A fresh key for an agent, made on the phone. The secret leaves only in the
/// setup the user copies; it is never saved.
class AgentKey {
  const AgentKey({required this.publicKey, required this.secretKey});

  final String publicKey;

  /// NEAR's `ed25519:<base58 of seed and public key>`, which the fliq
  /// connector reads.
  final String secretKey;

  static Future<AgentKey> generate() async {
    final seed = SecretKeyData.random(length: 32).bytes;
    final pair = await Ed25519().newKeyPairFromSeed(seed);
    final public = (await pair.extractPublicKey()).bytes;
    return AgentKey(
      publicKey: NearKey.encode(public),
      secretKey: 'ed25519:${Base58.encode([...seed, ...public])}',
    );
  }
}

/// Connects, changes and revokes agents. Each change comes back from the API
/// as vault calls this phone signs behind biometrics, so the vault itself
/// enforces the limits.
class Agents {
  static Agents instance = Agents();

  Future<List<Agent>> list() => FliqApi.instance.agents();

  /// Connects an agent. With [existingPublicKey] the agent made its own key;
  /// otherwise a key is made here and returned in the setup to paste.
  Future<(Agent, AgentSetup?)> connect({
    required String name,
    required AgentApp app,
    required AgentPolicy policy,
    String? existingPublicKey,
  }) async {
    final key = existingPublicKey == null ? await AgentKey.generate() : null;
    final (agent, steps) = await FliqApi.instance.connectAgent(
      name: name,
      publicKey: existingPublicKey ?? key!.publicKey,
      limits: policy.toJson(),
    );
    await _sign(steps, reason: 'Let $name pay from your vault');
    final setup = key == null
        ? null
        : AgentSetup(
            app: app,
            accountId: agent.agentId,
            secretKey: key.secretKey,
            apiUrl: ApiConfig.baseUrl,
            rpcUrl: ApiConfig.nearRpcUrl,
          );
    return (agent, setup);
  }

  Future<Agent> update(String agentId, AgentPolicy policy) async {
    final (agent, steps) = await FliqApi.instance.updateAgent(
      agentId,
      policy.toJson(),
    );
    await _sign(steps, reason: "Change this agent's limits");
    return agent;
  }

  Future<void> revoke(String agentId) async {
    final (_, steps) = await FliqApi.instance.revokeAgent(agentId);
    await _sign(steps, reason: 'Revoke this agent');
  }

  /// Signs and relays the steps in order, each with the next nonce.
  Future<void> _sign(List<SignStep> steps, {required String reason}) async {
    final owner = AccountStore.instance.user?.nearAccount;
    if (owner == null) {
      throw const PayoutNotReady('Choose your fliq name first.');
    }
    for (final step in steps) {
      await VaultSigner.instance.submit(
        sender: owner,
        reason: reason,
        build: (nonce, height, key) => DelegateAction.functionCall(
          from: owner,
          receiverId: step.receiverId,
          methodName: step.methodName,
          args: step.args,
          gas: step.gas,
          deposit: step.deposit,
          nonce: nonce,
          blockHeight: height,
          publicKey: key,
        ),
      );
    }
  }
}
