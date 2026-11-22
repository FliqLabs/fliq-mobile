import 'package:flutter/material.dart';

import '../../services/account_store.dart';
import '../../services/api_exception.dart';
import '../../services/fliq_api.dart';
import 'settings_widgets.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final Map<String, bool> _values = {
    'Received in your vault': true,
    'Payout paid': true,
    'Payout refunded': true,
    'An agent paid': true,
    'An agent was refused': true,
    'Daily cap almost reached': true,
    'Rate alert': false,
    'Weekly summary': false,
  };

  /// Switch titles and the API's names for them.
  static const _keys = {
    'Received in your vault': 'received',
    'Payout paid': 'payout_paid',
    'Payout refunded': 'payout_refunded',
    'An agent paid': 'agent_paid',
    'An agent was refused': 'agent_refused',
    'Daily cap almost reached': 'cap_almost_reached',
    'Weekly summary': 'weekly_summary',
  };

  Map<String, dynamic>? _server;

  @override
  void initState() {
    super.initState();
    if (AccountStore.instance.isSignedIn) _load();
  }

  Future<void> _load() async {
    try {
      final settings = await FliqApi.instance.notificationSettings();
      if (!mounted) return;
      setState(() {
        _server = settings;
        for (final entry in _keys.entries) {
          _values[entry.key] = settings[entry.value] as bool? ?? true;
        }
        final rate = settings['rate_alert'] as Map<String, dynamic>?;
        _values['Rate alert'] = rate?['enabled'] as bool? ?? false;
      });
    } on ApiException {
      // Keep the defaults on screen.
    }
  }

  Future<void> _save() async {
    final server = _server;
    if (server == null) return;
    final next = Map<String, dynamic>.of(server);
    for (final entry in _keys.entries) {
      next[entry.value] = _values[entry.key];
    }
    final rate = Map<String, dynamic>.of(
      server['rate_alert'] as Map<String, dynamic>? ??
          const {'currency': 'NGN', 'above': 1400},
    );
    rate['enabled'] = _values['Rate alert'];
    next['rate_alert'] = rate;
    try {
      _server = await FliqApi.instance.saveNotificationSettings(next);
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SettingsPage(
      title: 'Notifications',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        children: [
          ToggleGroup(
            label: 'MONEY',
            values: _values,
            titles: const [
              'Received in your vault',
              'Payout paid',
              'Payout refunded',
            ],
            onChanged: _setValue,
          ),
          const SizedBox(height: 24),
          ToggleGroup(
            label: 'AGENTS',
            values: _values,
            titles: const [
              'An agent paid',
              'An agent was refused',
              'Daily cap almost reached',
            ],
            subtitles: const {'Daily cap almost reached': 'At 80%'},
            onChanged: _setValue,
          ),
          const SizedBox(height: 24),
          ToggleGroup(
            label: 'RATES',
            values: _values,
            titles: const ['Rate alert', 'Weekly summary'],
            subtitles: const {'Rate alert': r"When $1 beats ₦1,400"},
            onChanged: _setValue,
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(6, 18, 6, 0),
            child: Text(
              'Your choices are saved now. Alerts start arriving once Fliq sends push notifications.',
              style: TextStyle(color: Color(0xFF777777), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  void _setValue(String title, bool value) {
    setState(() => _values[title] = value);
    _save();
  }
}
