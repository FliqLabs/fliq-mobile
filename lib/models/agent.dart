import 'dart:convert';

/// An AI agent allowed to pay from the vault within limits the vault
/// enforces, from `GET /agents`.
class Agent {
  const Agent({
    required this.agentId,
    required this.name,
    required this.state,
    required this.dailyCap,
    required this.perPayoutCap,
    required this.currencies,
    required this.savedAccountsOnly,
    required this.spentToday,
  });

  factory Agent.fromJson(Map<String, dynamic> json) {
    int amount(Object? money) =>
        double.tryParse(
          (money as Map<String, dynamic>?)?['amount']?.toString() ?? '',
        )?.round() ??
        0;
    return Agent(
      agentId: json['agent_id'] as String,
      name: json['name'] as String,
      state: json['state'] as String? ?? 'pending',
      dailyCap: amount(json['daily_cap']),
      perPayoutCap: amount(json['per_payout_cap']),
      currencies: [
        for (final currency in json['currencies'] as List<dynamic>? ?? const [])
          currency.toString().toUpperCase(),
      ],
      savedAccountsOnly: json['saved_accounts_only'] as bool? ?? true,
      spentToday: amount(json['spent_today']),
    );
  }

  /// The agent's own NEAR account, e.g. `claude-frank.fliq.near`.
  final String agentId;
  final String name;

  /// `pending` until the phone signs the policy, `active`, or `revoked`.
  final String state;

  /// Whole local units (naira when it may pay in naira).
  final int dailyCap;
  final int perPayoutCap;

  /// `NGN`, `KES`.
  final List<String> currencies;
  final bool savedAccountsOnly;
  final int spentToday;
}

/// One vault call the API asks the phone to sign, from an `AgentChange`.
class SignStep {
  const SignStep({
    required this.receiverId,
    required this.methodName,
    required this.args,
    required this.gas,
    required this.deposit,
  });

  /// Only function calls are signed on the phone; fliq's relayer creates
  /// accounts itself. Null for any other kind.
  static SignStep? fromJson(Map<String, dynamic> json) {
    if (json['kind'] != 'function_call') return null;
    final method = json['method_name'] as String?;
    final gas = BigInt.tryParse(json['gas']?.toString() ?? '');
    final deposit = BigInt.tryParse(json['deposit']?.toString() ?? '');
    if (method == null || gas == null || deposit == null) return null;
    return SignStep(
      receiverId: json['receiver_id'] as String,
      methodName: method,
      args: utf8.encode(
        canonicalJson(json['args'] as Map<String, dynamic>? ?? const {}),
      ),
      gas: gas,
      deposit: deposit,
    );
  }

  final String receiverId;
  final String methodName;

  /// The JSON arguments with keys sorted, exactly as signed.
  final List<int> args;
  final BigInt gas;
  final BigInt deposit;
}

/// JSON with every object's keys in order, so the same call always signs to
/// the same bytes, as the iPhone app does.
String canonicalJson(Object? value) {
  if (value is Map) {
    final keys = value.keys.map((k) => k.toString()).toList()..sort();
    return '{${keys.map((k) => '${jsonEncode(k)}:${canonicalJson(value[k])}').join(',')}}';
  }
  if (value is List) return '[${value.map(canonicalJson).join(',')}]';
  return jsonEncode(value);
}

/// The apps an agent can live in, and where its setup goes.
enum AgentApp {
  claude('Claude', 'Run this in a terminal'),
  codex('Codex', 'Add this to ~/.codex/config.toml'),
  cursor('Cursor', 'Add this to .cursor/mcp.json'),
  other('My agent', "Add this to your agent's MCP settings");

  const AgentApp(this.agentName, this.destination);

  final String agentName;
  final String destination;

  static AgentApp fromChoice(String choice) => switch (choice) {
    'Claude' => AgentApp.claude,
    'ChatGPT or Codex' => AgentApp.codex,
    'Cursor' => AgentApp.cursor,
    _ => AgentApp.other,
  };
}

/// What the user pastes into the agent's app: its account, its secret key,
/// and where fliq is. The secret is shown once and never saved.
class AgentSetup {
  const AgentSetup({
    required this.app,
    required this.accountId,
    required this.secretKey,
    required this.apiUrl,
    required this.rpcUrl,
  });

  /// The connector on npm, the same one the iPhone app sets up.
  static const package = '@fliqlabs/mcp';

  final AgentApp app;
  final String accountId;
  final String secretKey;
  final String apiUrl;
  final String rpcUrl;

  List<(String, String)> get _environment => [
    ('FLIQ_AGENT_ID', accountId),
    ('FLIQ_AGENT_PRIVATE_KEY', secretKey),
    ('FLIQ_API_URL', apiUrl),
    ('FLIQ_NEAR_RPC_URL', rpcUrl),
  ];

  String get snippet => switch (app) {
    AgentApp.claude =>
      'claude mcp add fliq \\\n'
          '${_environment.map((e) => '  --env ${e.$1}=${e.$2} \\').join('\n')}\n'
          '  -- npx -y $package',
    AgentApp.codex =>
      '[mcp_servers.fliq]\ncommand = "npx"\nargs = ["-y", "$package"]\n'
          'env = { ${_environment.map((e) => '${e.$1} = "${e.$2}"').join(', ')} }',
    AgentApp.cursor || AgentApp.other =>
      '{\n  "mcpServers": {\n    "fliq": {\n      "command": "npx",\n'
          '      "args": ["-y", "$package"],\n      "env": {\n'
          '${_environment.map((e) => '        "${e.$1}": "${e.$2}"').join(',\n')}\n'
          '      }\n    }\n  }\n}',
  };
}
