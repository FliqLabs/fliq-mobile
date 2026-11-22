import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/account_store.dart';
import '../services/api_exception.dart';
import '../services/fliq_api.dart';
import '../widgets/circle_icon_button.dart';

/// Email sign-in: send a one-time link, then paste it (or its token) here.
///
/// Pops with `true` once signed in.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  /// Pulls the token out of a pasted sign-in link, a `fliq://` link, or a
  /// bare `el_…` token. Null when the text isn't one of those.
  static String? tokenIn(String text) {
    final trimmed = text.trim();
    final uri = Uri.tryParse(trimmed);
    final fromQuery = uri?.queryParameters['token'];
    if (fromQuery != null && fromQuery.isNotEmpty) return fromQuery;
    if (trimmed.startsWith('el_') && !trimmed.contains(' ')) return trimmed;
    return null;
  }

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

enum _Stage { email, sent }

class _SignInScreenState extends State<SignInScreen> {
  final _emailController = TextEditingController();
  final _linkController = TextEditingController();
  _Stage _stage = _Stage.email;
  bool _isWorking = false;
  String? _error;

  bool get _emailLooksValid {
    final parts = _emailController.text.trim().split('@');
    return parts.length == 2 && parts[0].isNotEmpty && parts[1].contains('.');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _sendLink() async {
    if (!_emailLooksValid || _isWorking) return;
    setState(() {
      _isWorking = true;
      _error = null;
    });
    try {
      await FliqApi.instance.sendEmailLink(_emailController.text.trim());
      if (mounted) setState(() => _stage = _Stage.sent);
    } on ApiException catch (error) {
      if (mounted) {
        setState(
          () => _error = error.code == 'offline'
              ? error.message
              : "We couldn't send the link. Check the address and try again.",
        );
      }
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  Future<void> _pasteLink() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text ?? '';
    if (text.isEmpty) return;
    _linkController.text = text.trim();
    setState(() {});
    await _verify();
  }

  Future<void> _verify() async {
    final token = SignInScreen.tokenIn(_linkController.text);
    if (token == null) {
      setState(() => _error = "That doesn't look like a fliq sign-in link.");
      return;
    }
    setState(() {
      _isWorking = true;
      _error = null;
    });
    try {
      final user = await FliqApi.instance.verifyEmailLink(token);
      await AccountStore.instance.signedIn(user);
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (mounted) {
        setState(
          () => _error = error.code == 'offline'
              ? error.message
              : 'This link has expired or was already used. Send a new one.',
        );
      }
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: CircleIconButton(
                  key: const ValueKey('sign-in-back'),
                  icon: Icons.arrow_back_ios_new_rounded,
                  tooltip: 'Back',
                  size: 44,
                  borderColor: const Color(0xFF333333),
                  onPressed: () {
                    if (_stage == _Stage.sent) {
                      setState(() {
                        _stage = _Stage.email;
                        _error = null;
                      });
                    } else {
                      Navigator.of(context).pop(false);
                    }
                  },
                ),
              ),
              const SizedBox(height: 28),
              if (_stage == _Stage.email) ..._emailStep() else ..._sentStep(),
              if (_error != null) ...[
                const SizedBox(height: 14),
                Text(
                  _error!,
                  key: const ValueKey('sign-in-error'),
                  style: const TextStyle(
                    color: Color(0xFFE65D66),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _emailStep() => [
    const Text(
      'Sign in with email',
      style: TextStyle(
        color: Colors.white,
        fontSize: 30,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
    ),
    const SizedBox(height: 8),
    const Text(
      "We'll email you a one-time link. No password needed.",
      style: TextStyle(color: Color(0xFF9A9A9E), fontSize: 16),
    ),
    const SizedBox(height: 28),
    _Field(
      key: const ValueKey('sign-in-email'),
      controller: _emailController,
      hint: 'you@example.com',
      keyboardType: TextInputType.emailAddress,
      onChanged: (_) => setState(() {}),
      onSubmitted: (_) => _sendLink(),
    ),
    const SizedBox(height: 16),
    _PrimaryButton(
      key: const ValueKey('send-sign-in-link'),
      label: 'Email me a link',
      isWorking: _isWorking,
      onPressed: _emailLooksValid ? _sendLink : null,
    ),
  ];

  List<Widget> _sentStep() => [
    const Icon(Icons.mark_email_read_outlined, color: Colors.white, size: 44),
    const SizedBox(height: 16),
    const Text(
      'Check your email',
      style: TextStyle(
        color: Colors.white,
        fontSize: 30,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
    ),
    const SizedBox(height: 8),
    Text(
      'We sent a sign-in link to ${_emailController.text.trim()}. '
      'Copy the link from the email and paste it here.',
      style: const TextStyle(
        color: Color(0xFF9A9A9E),
        fontSize: 16,
        height: 1.35,
      ),
    ),
    const SizedBox(height: 24),
    _Field(
      key: const ValueKey('sign-in-link'),
      controller: _linkController,
      hint: 'Paste the link',
      keyboardType: TextInputType.url,
      onChanged: (_) => setState(() {}),
      onSubmitted: (_) => _verify(),
      suffix: IconButton(
        key: const ValueKey('paste-sign-in-link'),
        tooltip: 'Paste',
        onPressed: _isWorking ? null : _pasteLink,
        icon: const Icon(Icons.content_paste_rounded, color: Colors.white),
      ),
    ),
    const SizedBox(height: 16),
    _PrimaryButton(
      key: const ValueKey('verify-sign-in-link'),
      label: 'Sign in',
      isWorking: _isWorking,
      onPressed: _linkController.text.trim().isEmpty ? null : _verify,
    ),
    const SizedBox(height: 8),
    TextButton(
      key: const ValueKey('resend-sign-in-link'),
      onPressed: _isWorking
          ? null
          : () => setState(() {
              _stage = _Stage.email;
              _linkController.clear();
              _error = null;
            }),
      style: TextButton.styleFrom(foregroundColor: const Color(0xFF9A9A9E)),
      child: const Text('Use a different email or send again'),
    ),
  ];
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.hint,
    required this.keyboardType,
    required this.onChanged,
    required this.onSubmitted,
    this.suffix,
    super.key,
  });

  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: true,
      autocorrect: false,
      keyboardType: keyboardType,
      textInputAction: TextInputAction.go,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      style: const TextStyle(color: Colors.white, fontSize: 17),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF6E6E73)),
        filled: true,
        fillColor: const Color(0xFF161618),
        suffixIcon: suffix,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.isWorking,
    required this.onPressed,
    super.key,
  });

  final String label;
  final bool isWorking;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: FilledButton(
        onPressed: isWorking ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          disabledBackgroundColor: const Color(0xFF2A2A2C),
          disabledForegroundColor: const Color(0xFF6E6E73),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        child: isWorking
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(label),
      ),
    );
  }
}
