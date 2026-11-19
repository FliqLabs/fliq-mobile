import 'package:flutter/material.dart';

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
  }
}
