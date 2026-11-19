import 'package:flutter/material.dart';

import 'settings_widgets.dart';

enum AppLockDelay { immediately, oneMinute, fiveMinutes }

extension on AppLockDelay {
  String get label => switch (this) {
    AppLockDelay.immediately => 'Immediately',
    AppLockDelay.oneMinute => 'After 1 minute',
    AppLockDelay.fiveMinutes => 'After 5 minutes',
  };
}

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  bool _lockWithBiometrics = true;
  AppLockDelay _lockDelay = AppLockDelay.oneMinute;

  @override
  Widget build(BuildContext context) {
    return SettingsPage(
      title: 'Security',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        children: [
          const SectionLabel('PASSKEYS'),
          const SizedBox(height: 12),
          const SettingsTile(
            title: 'Synced passkey\nMade 14 Nov 2026 · used 4 days ago',
            trailing: StatusPill('Active'),
            icon: Icons.person_pin_outlined,
            showDivider: false,
          ),
          const SizedBox(height: 24),
          const SectionLabel('BACKUP'),
          const SizedBox(height: 12),
          SettingsTile(
            key: const ValueKey('account-backup'),
            title: 'Account backup',
            icon: Icons.settings_backup_restore_rounded,
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF777777),
            ),
            showDivider: false,
            onTap: () => Navigator.of(context).push<void>(
              MaterialPageRoute(builder: (_) => const AccountBackupScreen()),
            ),
          ),
          const SizedBox(height: 24),
          const SectionLabel('CAN MOVE YOUR MONEY'),
          const SizedBox(height: 12),
          SettingsTile(
            title: 'Another device\nRemove it if you no longer have it',
            trailing: const Text(
              'Remove',
              style: TextStyle(
                color: Color(0xFFE65D66),
                fontWeight: FontWeight.w600,
              ),
            ),
            icon: Icons.phone_iphone_rounded,
            showDivider: false,
            onTap: () => _confirmRemoveDevice(context),
          ),
          const SizedBox(height: 24),
          const SectionLabel('APP LOCK'),
          const SizedBox(height: 12),
          SettingsTile(
            title: 'Lock with biometrics',
            icon: Icons.fingerprint_rounded,
            trailing: Switch.adaptive(
              key: const ValueKey('lock-with-biometrics'),
              value: _lockWithBiometrics,
              onChanged: (value) => setState(() => _lockWithBiometrics = value),
              activeTrackColor: const Color(0xFF2EB467),
            ),
          ),
          const SettingsTile(
            title: 'Passcode',
            icon: Icons.lock_outline_rounded,
            trailing: Text('Set'),
          ),
          SettingsTile(
            title: 'Lock',
            icon: Icons.timer_outlined,
            showDivider: false,
            trailing: PopupMenuButton<AppLockDelay>(
              key: const ValueKey('lock-delay'),
              initialValue: _lockDelay,
              onSelected: (value) => setState(() => _lockDelay = value),
              color: const Color(0xFF2A2A2D),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              itemBuilder: (context) => [
                for (final delay in AppLockDelay.values)
                  CheckedPopupMenuItem<AppLockDelay>(
                    value: delay,
                    checked: delay == _lockDelay,
                    child: Text(delay.label),
                  ),
              ],
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _lockDelay.label,
                    style: const TextStyle(color: Color(0xFFAAAAAA)),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.unfold_more_rounded,
                    color: Color(0xFFAAAAAA),
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const SectionLabel('SENDING'),
          const SizedBox(height: 12),
          const SettingsTile(
            title: 'Biometrics to send',
            trailing: Text('Always on'),
          ),
          const SettingsTile(
            title: "Biometrics for agents' limits",
            trailing: Text('Always on'),
            showDivider: false,
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(6, 14, 6, 0),
            child: Text(
              "Nothing leaves your vault, and no agent's limits change, "
              'without your fingerprint, face or passcode.',
              style: TextStyle(color: Color(0xFF777777), fontSize: 13),
            ),
          ),
          const SizedBox(height: 24),
          const SectionLabel('DEVICES AND SESSIONS'),
          const SizedBox(height: 12),
          const _ThisDeviceTile(),
        ],
      ),
    );
  }

  Future<void> _confirmRemoveDevice(BuildContext context) async {
    final remove = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF202020),
        title: const Text('Remove this device?'),
        content: const Text(
          'It will no longer be able to move your money. You can add it '
          'again later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Remove',
              style: TextStyle(color: Color(0xFFE65D66)),
            ),
          ),
        ],
      ),
    );
    if (remove != true || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Devices can be removed once fliq is connected to its servers.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _ThisDeviceTile extends StatelessWidget {
  const _ThisDeviceTile();

  @override
  Widget build(BuildContext context) {
    return const SettingsTile(
      title: 'This phone\nThis device · active now',
      trailing: Icon(Icons.circle, color: Color(0xFF2EB467), size: 10),
      showDivider: false,
    );
  }
}

class AccountBackupScreen extends StatelessWidget {
  const AccountBackupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsPage(
      title: 'Account backup',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
        children: const [
          Icon(Icons.shield_outlined, color: Color(0xFFF5A623), size: 52),
          SizedBox(height: 14),
          Text(
            "This phone isn't set up",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Add this phone to your account from the Home screen first.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 16),
          ),
          SizedBox(height: 34),
          SectionLabel('HOW IT WORKS'),
          SizedBox(height: 12),
          SettingsTile(
            icon: Icons.phone_iphone_rounded,
            title:
                "A backup key is saved in your phone's password manager, next "
                'to your passwords.',
          ),
          SettingsTile(
            icon: Icons.settings_backup_restore_rounded,
            title:
                'On a new phone with the same account, sign in and fliq adds '
                'that phone to your account.',
          ),
          SettingsTile(
            icon: Icons.lock_outline_rounded,
            title:
                'Keep your account safe. Someone who gets into your password '
                'manager could reach your money.',
            showDivider: false,
          ),
        ],
      ),
    );
  }
}

class DevicesSettingsScreen extends StatelessWidget {
  const DevicesSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsPage(
      title: 'Devices and sessions',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        children: const [_ThisDeviceTile()],
      ),
    );
  }
}

/// "How your money is held", shown as a sheet from Settings.
class MoneyHeldSheet extends StatelessWidget {
  const MoneyHeldSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => const MoneyHeldSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    const body = TextStyle(color: Color(0xFFAAAAAA), fontSize: 16, height: 1.4);
    return const SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(28, 28, 28, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How your money is held',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 14),
            Text(
              'Your dollars sit in the fliq vault, a smart contract on NEAR, '
              'under your own account. Only a key on this phone can move '
              'them, and it asks for your fingerprint, face or passcode every '
              'time. If you turn on Account backup, a second key in your '
              "phone's password manager can add a new phone.",
              style: body,
            ),
            SizedBox(height: 16),
            Text(
              'fliq never holds your key. If fliq went away, your balance '
              'would still be on chain under your name.',
              style: body,
            ),
            SizedBox(height: 16),
            Text(
              'fliq-vault.near',
              style: TextStyle(
                color: Color(0xFF777777),
                fontSize: 14,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
