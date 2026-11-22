import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

import '../../services/account_store.dart';
import '../../services/api_exception.dart';
import '../../services/biometric_authenticator.dart';
import '../../services/fliq_api.dart';
import '../../utils/amount_input.dart';
import 'settings_widgets.dart';

class DailyLimitScreen extends StatefulWidget {
  const DailyLimitScreen({
    this.authenticator = const LocalBiometricAuthenticator(),
    super.key,
  });

  final BiometricAuthenticator authenticator;

  @override
  State<DailyLimitScreen> createState() => _DailyLimitScreenState();
}

class _DailyLimitScreenState extends State<DailyLimitScreen> {
  String? _savedLimit;
  String? _pendingNote;

  @override
  void initState() {
    super.initState();
    if (AccountStore.instance.isSignedIn) _loadLimits();
  }

  Future<void> _loadLimits() async {
    try {
      final limits = await FliqApi.instance.limits();
      if (!mounted) return;
      setState(() {
        _savedLimit = limits.dailyLimit == null
            ? null
            : '\$${_formatLimit(limits.dailyLimit!)} per day';
        _pendingNote = !limits.hasPendingRaise
            ? null
            : limits.pendingLimit == null
            ? 'Removing your limit takes effect ${_when(limits.pendingAt!)}.'
            : 'Rising to \$${_formatLimit(limits.pendingLimit!)} '
                  '${_when(limits.pendingAt!)}.';
      });
    } on ApiException {
      // Keep showing what we have; the screen still works.
    }
  }

  String _when(DateTime at) {
    final hours = at.difference(DateTime.now()).inHours;
    return hours <= 0 ? 'any minute now' : 'in about $hours hours';
  }

  @override
  Widget build(BuildContext context) {
    return SettingsPage(
      title: 'Daily limit',
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 42, 24, 24),
              children: [
                Icon(
                  Icons.verified_user_outlined,
                  color: Color(0xFFAAAAAA),
                  size: 48,
                ),
                SizedBox(height: 20),
                Text(
                  _savedLimit ?? 'No daily limit',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (_pendingNote != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _pendingNote!,
                    key: const ValueKey('daily-limit-pending'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFF5A623),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                SizedBox(height: 14),
                Text(
                  'Set the most that can leave your account in a day. If your phone is ever stolen, that is the most anyone could take.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFAAAAAA),
                    fontSize: 16,
                    height: 1.35,
                  ),
                ),
                SizedBox(height: 32),
                SectionLabel('HOW IT WORKS'),
                SizedBox(height: 12),
                SettingsTile(
                  title: 'Covers cash-outs, payments to people\nand sends to other wallets.',
                  icon: Icons.swap_vert_rounded,
                ),
                SettingsTile(
                  title: 'Lowering your limit is instant.',
                  icon: Icons.verified_user_outlined,
                ),
                SettingsTile(
                  title: 'Raising it takes 24 hours, and we tell you\nwhen it is asked for.',
                  icon: Icons.access_time_rounded,
                  showDivider: false,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: SizedBox(
              width: double.infinity,
              height: 58,
              child: OutlinedButton(
                key: const ValueKey('set-daily-limit'),
                onPressed: () => _showSetLimitSheet(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFF777777)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Set a limit'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSetLimitSheet(BuildContext context) {
    Navigator.of(context)
        .push<double>(
          MaterialPageRoute<double>(
            fullscreenDialog: true,
            builder: (_) =>
                _DailyLimitEntryScreen(authenticator: widget.authenticator),
          ),
        )
        .then((limit) {
          if (limit == null || !mounted) return;
          if (AccountStore.instance.isSignedIn) {
            _loadLimits();
          } else {
            setState(() => _savedLimit = '\$${_formatLimit(limit)} per day');
          }
        });
  }

  String _formatLimit(double limit) {
    final amount = limit.toStringAsFixed(
      limit.truncateToDouble() == limit ? 0 : 2,
    );
    final parts = amount.split('.');
    final whole = parts.first;
    final grouped = StringBuffer();
    for (var index = 0; index < whole.length; index++) {
      if (index > 0 && (whole.length - index) % 3 == 0) grouped.write(',');
      grouped.write(whole[index]);
    }
    return parts.length == 1
        ? grouped.toString()
        : '${grouped.toString()}.${parts.last}';
  }
}

class _DailyLimitEntryScreen extends StatefulWidget {
  const _DailyLimitEntryScreen({required this.authenticator});

  final BiometricAuthenticator authenticator;

  @override
  State<_DailyLimitEntryScreen> createState() => _DailyLimitEntryScreenState();
}

class _DailyLimitEntryScreenState extends State<_DailyLimitEntryScreen> {
  String _amount = '0';
  bool _isSaving = false;

  bool get _hasAmount => (double.tryParse(_amount) ?? 0) > 0;

  void _pressKey(String key) {
    setState(() => _amount = applyAmountKey(_amount, key));
  }

  String get _formattedAmount {
    final parts = _amount.split('.');
    final whole = parts.first;
    final grouped = StringBuffer();
    for (var index = 0; index < whole.length; index++) {
      if (index > 0 && (whole.length - index) % 3 == 0) grouped.write(',');
      grouped.write(whole[index]);
    }
    return parts.length == 1
        ? grouped.toString()
        : '${grouped.toString()}.${parts.last}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 64,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    SizedBox(
                      width: 92,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          key: const ValueKey('cancel-daily-limit'),
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Color(0xFF333333)),
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        'Daily limit',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 92),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    flex: 5,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'A day',
                            style: TextStyle(
                              color: Color(0xFFAAAAAA),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              const Text(
                                r'$',
                                style: TextStyle(
                                  color: Color(0xFFAAAAAA),
                                  fontSize: 32,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                              Text(
                                _formattedAmount,
                                key: const ValueKey('daily-limit-amount'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 62,
                                  height: 1,
                                  fontWeight: FontWeight.w300,
                                  letterSpacing: -2,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              'The most that can leave your account in a day.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFFAAAAAA),
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          for (final row in const [
                            ['1', '2', '3'],
                            ['4', '5', '6'],
                            ['7', '8', '9'],
                            ['.', '0', 'delete'],
                          ])
                            Expanded(
                              child: Row(
                                children: [
                                  for (final key in row)
                                    Expanded(
                                      child: _DailyLimitKey(
                                        key: ValueKey('daily-key-$key'),
                                        label: key,
                                        onTap: () => _pressKey(key),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              child: SizedBox(
                width: double.infinity,
                height: 58,
                child: OutlinedButton.icon(
                  key: const ValueKey('save-daily-limit'),
                  onPressed: _hasAmount && !_isSaving ? _save : null,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.fingerprint_rounded, size: 20),
                  label: Text(_isSaving ? 'Saving…' : 'Save with biometrics'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    disabledForegroundColor: const Color(0xFF555555),
                    side: const BorderSide(color: Color(0xFF393939)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final authenticated = await widget.authenticator.authenticate();
      if (!mounted) return;
      if (!authenticated) {
        _showMessage('Authentication was not completed.');
        return;
      }
      final amount = double.parse(_amount);
      var message = 'Daily limit saved.';
      if (AccountStore.instance.isSignedIn) {
        final limits = await FliqApi.instance.setDailyLimit(amount);
        if (!mounted) return;
        if (limits.hasPendingRaise) {
          message = 'Raising your limit takes 24 hours. We will tell you.';
        }
      }
      _showMessage(message);
      Navigator.of(context).pop(amount);
    } on ApiException catch (error) {
      if (!mounted) return;
      _showMessage(error.message);
    } on LocalAuthException catch (error) {
      if (!mounted) return;
      debugPrint('Daily limit biometric authentication failed: $error');
      _showMessage(switch (error.code) {
        LocalAuthExceptionCode.noCredentialsSet ||
        LocalAuthExceptionCode.noBiometricsEnrolled ||
        LocalAuthExceptionCode.noBiometricHardware =>
          'Set up biometrics or a device passcode to save your limit.',
        LocalAuthExceptionCode.userCanceled ||
        LocalAuthExceptionCode.systemCanceled ||
        LocalAuthExceptionCode.timeout => 'Authentication was cancelled.',
        _ => 'Biometric unlock is unavailable. Please try again.',
      });
    } on PlatformException catch (error) {
      if (!mounted) return;
      debugPrint('Daily limit biometric authentication failed: $error');
      _showMessage('Biometric unlock is unavailable. Please try again.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }
}

class _DailyLimitKey extends StatelessWidget {
  const _DailyLimitKey({required this.label, required this.onTap, super.key});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDelete = label == 'delete';
    final isDecimal = label == '.';
    return Semantics(
      button: true,
      label: isDelete ? 'Delete' : label,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
          shape: const CircleBorder(),
          padding: EdgeInsets.zero,
        ),
        child: isDelete
            ? const Icon(Icons.backspace_outlined, size: 28)
            : Text(
                label,
                style: TextStyle(
                  fontSize: isDecimal ? 22 : 30,
                  fontWeight: FontWeight.w400,
                ),
              ),
      ),
    );
  }
}
