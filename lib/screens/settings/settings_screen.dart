import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/biometric_authenticator.dart';
import '../welcome_screen.dart';
import 'accounts_settings_screen.dart';
import 'agents_settings_screen.dart';
import 'live_rates_sheet.dart';
import 'daily_limit_screen.dart';
import 'notification_settings_screen.dart';
import 'security_settings_screen.dart';
import 'settings_widgets.dart';
import '../../services/api_exception.dart';
import '../../services/fliq_api.dart';
import '../../utils/formatters.dart';
import '../../services/account_store.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Uint8List? _avatarBytes;
  final Future<String> _serverVersion = FliqApi.instance.checkHealth();

  String _bankValue = 'Not added';
  String _limitValue = 'Not set';
  String _devicesValue = '1 signed in';

  @override
  void initState() {
    super.initState();
    if (AccountStore.instance.isSignedIn) _loadSummary();
  }

  /// Fills the row values from the server. Each part fails on its own.
  Future<void> _loadSummary() async {
    final api = FliqApi.instance;
    try {
      final own = (await api.recipients()).where((r) => r.own).toList();
      if (mounted && own.isNotEmpty) {
        setState(
          () => _bankValue = '${own.first.bankName} •••• ${own.first.last4}',
        );
      }
    } on ApiException {
      // Leave the default.
    }
    try {
      final limits = await api.limits();
      if (mounted && limits.dailyLimit != null) {
        setState(
          () => _limitValue = '\$${groupDigits(limits.dailyLimit!)} a day',
        );
      }
    } on ApiException {
      // Leave the default.
    }
    try {
      final sessions = await api.deviceSessions();
      if (mounted) {
        setState(() => _devicesValue = '${sessions.length} signed in');
      }
    } on ApiException {
      // Leave the default.
    }
  }

  void _open(BuildContext context, Widget page) {
    Navigator.of(context)
        .push<void>(MaterialPageRoute<void>(builder: (_) => page));
  }

  Future<void> _pickAvatar() async {
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (image == null) return;
      final bytes = await image.readAsBytes();
      if (mounted) setState(() => _avatarBytes = bytes);
    } on PlatformException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not open photos: ${error.message ?? error.code}',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SettingsPage(
      title: 'Settings',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        children: [
          _ProfileCard(
            avatarBytes: _avatarBytes,
            onTap: () => _showAvatarSheet(context),
          ),
          const SizedBox(height: 28),
          SettingsGroup(
            label: 'ACCOUNT',
            rows: [
              SettingsRow(
                icon: Icons.account_balance_outlined,
                title: 'Your bank account',
                value: _bankValue,
                onTap: () => _open(context, const AccountsSettingsScreen()),
              ),
              SettingsRow(
                icon: Icons.language_rounded,
                title: 'Home currency',
                // Display only, like the iPhone app: it does not open a page.
                value: '🇳🇬   NGN',
              ),
              SettingsRow(
                icon: Icons.notifications_none_rounded,
                title: 'Notifications',
                onTap: () => _open(context, const NotificationSettingsScreen()),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SettingsGroup(
            label: 'LIMITS',
            rows: [
              SettingsRow(
                icon: Icons.bubble_chart_outlined,
                iconColor: const Color(0xFFE7835C),
                title: 'Agents',
                value: '0 active',
                onTap: () => _open(context, const AgentsSettingsScreen()),
              ),
              SettingsRow(
                icon: Icons.pie_chart_outline_rounded,
                title: 'Your daily limit',
                value: _limitValue,
                onTap: () => _open(context, const DailyLimitScreen()),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SettingsGroup(
            label: 'SECURITY',
            rows: [
              SettingsRow(
                icon: Icons.person_pin_outlined,
                title: 'Passkeys',
                value: 'This phone',
                onTap: () => _open(context, const SecuritySettingsScreen()),
              ),
              SettingsRow(
                icon: Icons.phone_iphone_rounded,
                title: 'Devices and sessions',
                value: _devicesValue,
                onTap: () => _open(context, const DevicesSettingsScreen()),
              ),
              SettingsRow(
                icon: Icons.lock_outline_rounded,
                title: 'How your money is held',
                onTap: () => MoneyHeldSheet.show(context),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SettingsGroup(
            label: 'OTHERS',
            rows: [
              SettingsRow(
                icon: Icons.swap_horiz_rounded,
                title: 'Live rates, all providers',
                onTap: () => LiveRatesSheet.show(context),
              ),
              SettingsRow(
                icon: Icons.logout_rounded,
                title: 'Sign out',
                onTap: () => _showSignOutDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 24),
          FutureBuilder<String>(
            future: _serverVersion,
            builder: (context, snapshot) {
              final String text;
              if (snapshot.connectionState == ConnectionState.waiting) {
                text = 'Checking server…';
              } else if (snapshot.hasError) {
                text = "Can't reach server";
              } else {
                text = 'Server connected · v${snapshot.data}';
              }
              return Text(
                text,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF777777), fontSize: 13),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showAvatarSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF171717),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => SafeArea(
        top: false,
        child: SizedBox(
          height: 500,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 12, 28, 24),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF777777),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Spacer(),
                    const Text(
                      'Edit avatar',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      key: const ValueKey('close-avatar-sheet'),
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                      style: IconButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF393939)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 42),
                _Avatar(size: 144, fontSize: 46, imageBytes: _avatarBytes),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF333333)),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    '@${AccountStore.instance.handle}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: FilledButton.icon(
                    key: const ValueKey('add-avatar-photo'),
                    onPressed: _pickAvatar,
                    icon: const Icon(Icons.image_outlined),
                    label: const Text('Add photo'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showSignOutDialog(BuildContext context) async {
    final signOut = await showDialog<bool>(
      context: context,
      barrierColor: const Color(0x99000000),
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF2A2A2D),
        insetPadding: const EdgeInsets.symmetric(horizontal: 64),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sign out of fliq on this phone?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your vault and its money stay on NEAR. You can sign back in '
                'with your passkey.',
                style: TextStyle(
                  color: Color(0xFFAAAAAA),
                  fontSize: 15,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  key: const ValueKey('confirm-sign-out'),
                  onPressed: () => Navigator.pop(context, true),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF3A3A3D),
                    foregroundColor: const Color(0xFFFF453A),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    shape: const StadiumBorder(),
                  ),
                  child: const Text('Sign out'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (signOut != true || !context.mounted) return;
    final navigator = Navigator.of(context);
    await AccountStore.instance.signOut();
    // Back to the welcome screen, clearing everything behind it.
    await navigator.pushAndRemoveUntil<void>(
      MaterialPageRoute(
        builder: (_) => const WelcomeScreen(
          biometricAuthenticator: LocalBiometricAuthenticator(),
        ),
      ),
      (_) => false,
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.onTap, required this.avatarBytes});

  final VoidCallback onTap;
  final Uint8List? avatarBytes;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF191919),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        key: const ValueKey('settings-profile'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              _Avatar(
                size: 76,
                fontSize: 28,
                imageBytes: avatarBytes,
                showCamera: true,
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your profile',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '@${AccountStore.instance.handle}',
                      style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 15),
                    ),
                  ],
                ),
              ),
              const StatusPill('Verified'),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.size,
    required this.fontSize,
    this.imageBytes,
    this.showCamera = false,
  });

  final double size;
  final double fontSize;
  final Uint8List? imageBytes;
  final bool showCamera;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: ClipOval(
              child: imageBytes == null
                  ? Container(
                      color: const Color(0xFF30473E),
                      alignment: Alignment.center,
                      child: Text(
                        'OF',
                        style: TextStyle(
                          color: const Color(0xFF66D2AC),
                          fontSize: fontSize,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    )
                  : Image.memory(imageBytes!, fit: BoxFit.cover),
            ),
          ),
          if (showCamera)
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt_outlined,
                  color: Colors.black,
                  size: 15,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
