import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

import '../../data/sample_data.dart';
import '../../services/biometric_authenticator.dart';
import '../../utils/formatters.dart';
import 'settings_widgets.dart';

/// An agent you have connected, and the limits it must stay within.
class AgentConnection {
  const AgentConnection({
    required this.name,
    required this.perDay,
    required this.perPayment,
    required this.paysNigeria,
    required this.paysKenya,
    required this.savedAccountsOnly,
    this.spentToday = 0,
  });

  final String name;
  final int perDay;
  final int perPayment;
  final bool paysNigeria;
  final bool paysKenya;
  final bool savedAccountsOnly;
  final int spentToday;

  String get countriesLabel {
    final codes = [if (paysKenya) 'KES', if (paysNigeria) 'NGN'];
    return codes.length == 1
        ? '${codes.first} only'
        : '${codes.join(', ')} only';
  }
}

class AgentsSettingsScreen extends StatefulWidget {
  const AgentsSettingsScreen({
    this.authenticator = const LocalBiometricAuthenticator(),
    super.key,
  });

  final BiometricAuthenticator authenticator;

  @override
  State<AgentsSettingsScreen> createState() => _AgentsSettingsScreenState();
}

class _AgentsSettingsScreenState extends State<AgentsSettingsScreen> {
  final List<AgentConnection> _agents = [];

  Future<void> _connect() async {
    final agent = await Navigator.of(context).push<AgentConnection>(
      MaterialPageRoute<AgentConnection>(
        builder: (_) => ConnectAgentScreen(authenticator: widget.authenticator),
      ),
    );
    if (agent != null && mounted) setState(() => _agents.add(agent));
  }

  Future<void> _changeLimits(int index) async {
    final updated = await Navigator.of(context).push<AgentConnection>(
      MaterialPageRoute<AgentConnection>(
        builder: (_) => AgentPermissionsScreen(
          name: _agents[index].name,
          authenticator: widget.authenticator,
          initial: _agents[index],
        ),
      ),
    );
    if (updated != null && mounted) setState(() => _agents[index] = updated);
  }

  Future<void> _revoke(int index) async {
    final agent = _agents[index];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF202020),
        title: Text('Revoke ${agent.name}\'s key?'),
        content: const Text(
          'It will stop being able to pay anyone straight away.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            key: const ValueKey('confirm-revoke'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Revoke',
              style: TextStyle(color: Color(0xFFE65D66)),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) setState(() => _agents.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    return SettingsPage(
      title: 'Agents',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        children: [
          for (var i = 0; i < _agents.length; i++) ...[
            _AgentCard(
              agent: _agents[i],
              onChangeLimits: () => _changeLimits(i),
              onRevoke: () => _revoke(i),
            ),
            const SizedBox(height: 24),
          ],
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Column(
              children: [
                SettingsTile(
                  title: 'Connect an agent',
                  trailing: const Icon(Icons.add, color: Colors.white),
                  onTap: _connect,
                ),
                const SettingsTile(
                  title: 'Enforced by\n${SampleData.nearAccount}',
                  trailing: Icon(
                    Icons.verified_user_outlined,
                    color: Color(0xFF777777),
                  ),
                  showDivider: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AgentCard extends StatelessWidget {
  const _AgentCard({
    required this.agent,
    required this.onChangeLimits,
    required this.onRevoke,
  });

  final AgentConnection agent;
  final VoidCallback onChangeLimits;
  final VoidCallback onRevoke;

  @override
  Widget build(BuildContext context) {
    final progress = agent.perDay == 0 ? 0.0 : agent.spentToday / agent.perDay;
    return Column(
      key: ValueKey('agent-card-${agent.name}'),
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E1E),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.auto_awesome_outlined, color: Colors.white),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              agent.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.circle, color: Color(0xFFF5A623), size: 6),
            const SizedBox(width: 4),
            const Text(
              'Connecting',
              style: TextStyle(
                color: Color(0xFFF5A623),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Spent today',
          style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 14),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            const Text(
              '₦',
              style: TextStyle(color: Color(0xFF8E8E93), fontSize: 22),
            ),
            Text(
              groupDigits(agent.spentToday),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
        ),
        Text.rich(
          TextSpan(
            style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 15),
            children: [
              const TextSpan(text: 'of '),
              TextSpan(
                text: formatNaira(agent.perDay),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const TextSpan(text: ' a day'),
            ],
          ),
        ),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: progress.clamp(0, 1),
            minHeight: 3,
            backgroundColor: const Color(0xFF2A2A2A),
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _AgentFact(
                label: 'Per payout',
                value: formatNaira(agent.perPayment),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _AgentFact(label: 'Pays', value: agent.countriesLabel),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                key: const ValueKey('agent-change-limits'),
                onPressed: onChangeLimits,
                style: _cardButtonStyle,
                child: const Text('Change limits'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton(
                key: const ValueKey('agent-revoke'),
                onPressed: onRevoke,
                style: _cardButtonStyle,
                child: const Text('Revoke key'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  static final _cardButtonStyle = OutlinedButton.styleFrom(
    foregroundColor: Colors.white,
    minimumSize: const Size.fromHeight(48),
    side: const BorderSide(color: Color(0xFF3A3A3A)),
    textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );
}

class _AgentFact extends StatelessWidget {
  const _AgentFact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF191919),
        borderRadius: BorderRadius.circular(12),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text.rich(
          TextSpan(
            style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 14),
            children: [
              TextSpan(text: '$label  '),
              TextSpan(
                text: value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ConnectAgentScreen extends StatelessWidget {
  const ConnectAgentScreen({required this.authenticator, super.key});

  final BiometricAuthenticator authenticator;

  static const _choices = [
    _AgentChoice(
      name: 'Claude',
      description: 'Claude Code and Claude Desktop',
      icon: Icons.auto_awesome,
      iconColor: Color(0xFFD77E5D),
    ),
    _AgentChoice(
      name: 'ChatGPT or Codex',
      description: 'Codex in the terminal or the IDE',
      icon: Icons.all_inclusive_rounded,
      iconColor: Colors.black,
    ),
    _AgentChoice(
      name: 'Cursor',
      description: 'The Cursor editor',
      icon: Icons.change_history_rounded,
      iconColor: Colors.black,
    ),
    _AgentChoice(
      name: 'Another agent',
      description: 'Any app that runs MCP servers',
      icon: Icons.auto_awesome_outlined,
      iconColor: Colors.white,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SettingsPage(
      title: 'Connect an agent',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        children: [
          const Text(
            'Which app is your agent in?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 23,
              height: 1.15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'fliq makes its key and sets its limits. You paste one line into the app.',
            style: TextStyle(
              color: Color(0xFFAAAAAA),
              fontSize: 14,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: ColoredBox(
              color: const Color(0xFF191919),
              child: Column(
                children: [
                  for (var index = 0; index < _choices.length; index++)
                    _AgentChoiceTile(
                      choice: _choices[index],
                      showDivider: index < _choices.length - 1,
                      onTap: () => _openAgent(context, _choices[index].name),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            key: const ValueKey('agent-already-has-key'),
            onPressed: () => _openAgent(context, 'My agent'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFAAAAAA),
            ),
            child: const Text('My agent already has a key'),
          ),
        ],
      ),
    );
  }

  void _openAgent(BuildContext context, String name) {
    Navigator.of(context)
        .push<AgentConnection>(
          MaterialPageRoute<AgentConnection>(
            builder: (_) => AgentPermissionsScreen(
              name: name,
              authenticator: authenticator,
            ),
          ),
        )
        .then((agent) {
          if (agent != null && context.mounted) {
            Navigator.of(context).pop(agent);
          }
        });
  }
}

class _AgentChoice {
  const _AgentChoice({
    required this.name,
    required this.description,
    required this.icon,
    required this.iconColor,
  });

  final String name;
  final String description;
  final IconData icon;
  final Color iconColor;
}

class _AgentChoiceTile extends StatelessWidget {
  const _AgentChoiceTile({
    required this.choice,
    required this.showDivider,
    required this.onTap,
  });

  final _AgentChoice choice;
  final bool showDivider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final customAgent = choice.name == 'Another agent';
    return Material(
      color: const Color(0xFF191919),
      child: InkWell(
        key: ValueKey('connect-agent-${choice.name}'),
        onTap: onTap,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: customAgent
                          ? const Color(0xFF252525)
                          : Colors.white,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(choice.icon, size: 21, color: choice.iconColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          choice.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          choice.description,
                          style: const TextStyle(
                            color: Color(0xFFAAAAAA),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF777777),
                  ),
                ],
              ),
            ),
            if (showDivider) const Divider(height: 1, thickness: 1, indent: 14),
          ],
        ),
      ),
    );
  }
}

class AgentPermissionsScreen extends StatefulWidget {
  const AgentPermissionsScreen({
    required this.name,
    required this.authenticator,
    this.initial,
    super.key,
  });

  final String name;
  final BiometricAuthenticator authenticator;

  /// Existing limits when changing an agent that is already connected.
  final AgentConnection? initial;

  @override
  State<AgentPermissionsScreen> createState() => _AgentPermissionsScreenState();
}

class _AgentPermissionsScreenState extends State<AgentPermissionsScreen> {
  late int _perDay = widget.initial?.perDay ?? 30000;
  late int _perPayment = widget.initial?.perPayment ?? 15000;
  late bool _paysNigeria = widget.initial?.paysNigeria ?? true;
  late bool _paysKenya = widget.initial?.paysKenya ?? true;
  late bool _savedAccountsOnly = widget.initial?.savedAccountsOnly ?? true;
  bool _isConnecting = false;

  static const _limitStep = 5000;

  @override
  Widget build(BuildContext context) {
    final canConnect = _paysNigeria || _paysKenya;
    return SettingsPage(
      title: widget.name,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              children: [
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: widget.name == 'Claude'
                              ? const Color(0xFFFFF8F3)
                              : Colors.white,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          _iconForAgent(widget.name),
                          color: _iconColorForAgent(widget.name),
                          size: 30,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: SectionLabel('WHAT IT MAY DO'),
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: ColoredBox(
                    color: const Color(0xFF191919),
                    child: Column(
                      children: [
                        _LimitRow(
                          key: const ValueKey('agent-daily-limit'),
                          id: 'daily',
                          label: 'Per day',
                          value: formatNaira(_perDay),
                          canDecrease: _perDay > _limitStep,
                          onDecrease: () =>
                              setState(() => _perDay -= _limitStep),
                          onIncrease: () =>
                              setState(() => _perDay += _limitStep),
                        ),
                        _LimitRow(
                          key: const ValueKey('agent-payment-limit'),
                          id: 'payment',
                          label: 'Per payment',
                          value: formatNaira(_perPayment),
                          canDecrease: _perPayment > _limitStep,
                          onDecrease: () =>
                              setState(() => _perPayment -= _limitStep),
                          onIncrease: () =>
                              setState(() => _perPayment += _limitStep),
                        ),
                        _CountryAccessRow(
                          nigeriaEnabled: _paysNigeria,
                          kenyaEnabled: _paysKenya,
                          onNigeriaChanged: (value) =>
                              setState(() => _paysNigeria = value),
                          onKenyaChanged: (value) =>
                              setState(() => _paysKenya = value),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 2, 8, 2),
                          child: Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Only my saved accounts',
                                  style: TextStyle(
                                    color: Color(0xFFAAAAAA),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Switch.adaptive(
                                key: const ValueKey('agent-saved-only'),
                                value: _savedAccountsOnly,
                                activeTrackColor: const Color(0xFF2EB467),
                                onChanged: (value) =>
                                    setState(() => _savedAccountsOnly = value),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF191919),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${widget.name} can pay up to ${formatNaira(_perPayment)} at a time, ${formatNaira(_perDay)} a day, to bank accounts in ${_countriesDescription()}, for a year or until you revoke it.',
                    key: const ValueKey('agent-permission-summary'),
                    style: const TextStyle(
                      color: Color(0xFFAAAAAA),
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton.icon(
                key: const ValueKey('connect-agent-face-id'),
                onPressed: canConnect && !_isConnecting ? _connect : null,
                icon: _isConnecting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Icon(Icons.fingerprint_rounded, size: 19),
                label: Text(
                  _isConnecting ? 'Connecting…' : 'Connect with biometrics',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: const Color(0xFF444444),
                  disabledForegroundColor: const Color(0xFF888888),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _countriesDescription() {
    if (_paysNigeria && _paysKenya) return 'Nigeria and Kenya';
    if (_paysNigeria) return 'Nigeria';
    if (_paysKenya) return 'Kenya';
    return 'no countries';
  }

  Future<void> _connect() async {
    try {
      final authenticated = await widget.authenticator.authenticate();
      if (!mounted) return;
      if (!authenticated) {
        _showMessage('Authentication was not completed.');
        return;
      }
      setState(() => _isConnecting = true);
      await Future<void>.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      setState(() => _isConnecting = false);
      // The API will create the agent's key here. For now the agent is
      // added locally so the Agents screen can show it.
      Navigator.of(context).pop(
        AgentConnection(
          name: widget.name,
          perDay: _perDay,
          perPayment: _perPayment,
          paysNigeria: _paysNigeria,
          paysKenya: _paysKenya,
          savedAccountsOnly: _savedAccountsOnly,
          spentToday: widget.initial?.spentToday ?? 0,
        ),
      );
    } on LocalAuthException catch (error) {
      if (!mounted) return;
      debugPrint('Agent biometric authentication failed: $error');
      _showMessage(_authenticationMessage(error.code));
    } on PlatformException catch (error) {
      if (!mounted) return;
      debugPrint('Agent biometric authentication failed: $error');
      _showMessage(
        'Biometric unlock is unavailable. Please try again or use your device passcode.',
      );
    }
  }

  String _authenticationMessage(LocalAuthExceptionCode code) {
    return switch (code) {
      LocalAuthExceptionCode.noCredentialsSet ||
      LocalAuthExceptionCode.noBiometricsEnrolled ||
      LocalAuthExceptionCode.noBiometricHardware =>
        'Set up biometrics or a device passcode to connect an agent.',
      LocalAuthExceptionCode.userCanceled ||
      LocalAuthExceptionCode.systemCanceled ||
      LocalAuthExceptionCode.timeout => 'Authentication was cancelled.',
      _ => 'Biometric unlock is unavailable. Please try again.',
    };
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  IconData _iconForAgent(String name) => switch (name) {
    'Claude' => Icons.auto_awesome,
    'ChatGPT or Codex' => Icons.all_inclusive_rounded,
    'Cursor' => Icons.change_history_rounded,
    _ => Icons.auto_awesome_outlined,
  };

  Color _iconColorForAgent(String name) => switch (name) {
    'Claude' => const Color(0xFFD77E5D),
    'ChatGPT or Codex' || 'Cursor' => Colors.black,
    _ => Colors.white,
  };
}

class _LimitRow extends StatelessWidget {
  const _LimitRow({
    required this.id,
    required this.label,
    required this.value,
    required this.canDecrease,
    required this.onDecrease,
    required this.onIncrease,
    super.key,
  });

  final String id;
  final String label;
  final String value;
  final bool canDecrease;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFFAAAAAA),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          _LimitButton(
            key: ValueKey('agent-$id-limit-decrease'),
            icon: Icons.remove,
            onPressed: canDecrease ? onDecrease : null,
          ),
          Expanded(
            flex: 2,
            child: Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          _LimitButton(
            key: ValueKey('agent-$id-limit-increase'),
            icon: Icons.add,
            onPressed: onIncrease,
          ),
        ],
      ),
    );
  }
}

class _LimitButton extends StatelessWidget {
  const _LimitButton({required this.icon, required this.onPressed, super.key});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints.tightFor(width: 36, height: 36),
      style: IconButton.styleFrom(
        backgroundColor: const Color(0xFF252525),
        foregroundColor: Colors.white,
        disabledForegroundColor: const Color(0xFF555555),
      ),
      icon: Icon(icon, size: 17),
    );
  }
}

class _CountryAccessRow extends StatelessWidget {
  const _CountryAccessRow({
    required this.nigeriaEnabled,
    required this.kenyaEnabled,
    required this.onNigeriaChanged,
    required this.onKenyaChanged,
  });

  final bool nigeriaEnabled;
  final bool kenyaEnabled;
  final ValueChanged<bool> onNigeriaChanged;
  final ValueChanged<bool> onKenyaChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 10, 6),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Pays to',
              style: TextStyle(
                color: Color(0xFFAAAAAA),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          _CountryPermissionChip(
            key: const ValueKey('agent-country-nigeria'),
            flag: '🇳🇬',
            label: 'Nigeria',
            selected: nigeriaEnabled,
            onTap: () => onNigeriaChanged(!nigeriaEnabled),
          ),
          const SizedBox(width: 6),
          _CountryPermissionChip(
            key: const ValueKey('agent-country-kenya'),
            flag: '🇰🇪',
            label: 'Kenya',
            selected: kenyaEnabled,
            onTap: () => onKenyaChanged(!kenyaEnabled),
          ),
        ],
      ),
    );
  }
}

class _CountryPermissionChip extends StatelessWidget {
  const _CountryPermissionChip({
    required this.flag,
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String flag;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Colors.white : const Color(0xFF2A2A2A),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              Text(flag, style: const TextStyle(fontSize: 11)),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.black : const Color(0xFFAAAAAA),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
