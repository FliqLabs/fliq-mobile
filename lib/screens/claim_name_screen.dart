import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/payment.dart';
import '../services/account_store.dart';
import '../services/api_exception.dart';
import '../services/fliq_api.dart';
import '../services/vault_signer.dart';

enum _NameStatus { empty, invalid, checking, available, taken, unreachable }

/// "Claim your name": picks the fliq name and creates the NEAR account and
/// vault behind it, owned by this phone's own key.
class ClaimNameScreen extends StatefulWidget {
  const ClaimNameScreen({super.key});

  @override
  State<ClaimNameScreen> createState() => _ClaimNameScreenState();
}

class _ClaimNameScreenState extends State<ClaimNameScreen> {
  final _controller = TextEditingController();
  Timer? _delay;
  _NameStatus _status = _NameStatus.empty;
  bool _isClaiming = false;
  String? _error;

  String? get _name => validFliqName(_controller.text);

  @override
  void dispose() {
    _delay?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    _delay?.cancel();
    final name = _name;
    setState(() {
      _error = null;
      _status = text.trim().isEmpty
          ? _NameStatus.empty
          : name == null
          ? _NameStatus.invalid
          : _NameStatus.checking;
    });
    if (name == null) return;
    _delay = Timer(const Duration(milliseconds: 300), () => _check(name));
  }

  Future<void> _check(String name) async {
    try {
      final result = await FliqApi.instance.checkName(name);
      if (!mounted || name != _name) return;
      setState(
        () => _status = result.available
            ? _NameStatus.available
            : result.reason == 'invalid'
            ? _NameStatus.invalid
            : _NameStatus.taken,
      );
    } on ApiException {
      if (mounted && name == _name) {
        setState(() => _status = _NameStatus.unreachable);
      }
    }
  }

  Future<void> _claim() async {
    final name = _name;
    if (name == null || _status != _NameStatus.available || _isClaiming) {
      return;
    }
    setState(() {
      _isClaiming = true;
      _error = null;
    });
    try {
      // This phone's key becomes the account's only full-access key.
      final publicKey = await VaultSigner.instance.keys.publicKey();
      final user = await FliqApi.instance.claimName(name, publicKey: publicKey);
      await AccountStore.instance.signedIn(user);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        if (error.status == 409) {
          _status = _NameStatus.taken;
        } else {
          _error = error.code == 'offline'
              ? "We couldn't reach fliq. Check your connection and try again."
              : error.message;
        }
      });
    } finally {
      if (mounted) setState(() => _isClaiming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (_status) {
      _NameStatus.empty => (
        'Letters, digits and hyphens, up to 32',
        const Color(0xFF8E8E93),
        null,
      ),
      _NameStatus.invalid => (
        'Letters, digits and hyphens, up to 32',
        const Color(0xFFF5A623),
        Icons.info_outline_rounded,
      ),
      _NameStatus.checking => (
        'Checking…',
        const Color(0xFF8E8E93),
        Icons.hourglass_empty_rounded,
      ),
      _NameStatus.available => (
        'Available',
        const Color(0xFF2EB467),
        Icons.check_circle_rounded,
      ),
      _NameStatus.taken => (
        'Taken',
        const Color(0xFFE65D66),
        Icons.cancel_rounded,
      ),
      _NameStatus.unreachable => (
        "Can't check right now",
        const Color(0xFFF5A623),
        Icons.wifi_off_rounded,
      ),
    };

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Claim your name',
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Pay and get paid by it, anywhere on fliq',
              style: TextStyle(color: Color(0xFF9A9A9E), fontSize: 16),
            ),
            const SizedBox(height: 28),
            TextField(
              key: const ValueKey('claim-name-field'),
              controller: _controller,
              autofocus: true,
              autocorrect: false,
              enabled: !_isClaiming,
              onChanged: _onChanged,
              onSubmitted: (_) => _claim(),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9-]')),
                LengthLimitingTextInputFormatter(32),
              ],
              style: const TextStyle(color: Colors.white, fontSize: 20),
              decoration: InputDecoration(
                prefixText: '@ ',
                prefixStyle: const TextStyle(
                  color: Color(0xFF8E8E93),
                  fontSize: 20,
                ),
                hintText: 'yourname',
                hintStyle: const TextStyle(color: Color(0xFF6E6E73)),
                filled: true,
                fillColor: const Color(0xFF161618),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 18,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              key: const ValueKey('claim-name-status'),
              children: [
                if (icon != null) ...[
                  Icon(icon, color: color, size: 16),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(color: color, fontSize: 14),
                  ),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: const TextStyle(color: Color(0xFFE65D66), fontSize: 14),
              ),
            ],
            const Spacer(),
            if (_isClaiming)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  'Creating your account. This can take up to a minute.',
                  style: TextStyle(color: Color(0xFF9A9A9E), fontSize: 14),
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  'Free · yours for life · one tap to claim',
                  style: TextStyle(color: Color(0xFF9A9A9E), fontSize: 14),
                ),
              ),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                key: const ValueKey('claim-name'),
                onPressed: _status == _NameStatus.available && !_isClaiming
                    ? _claim
                    : null,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: const Color(0xFF2A2A2C),
                  disabledForegroundColor: const Color(0xFF6E6E73),
                  shape: const StadiumBorder(),
                  textStyle: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: _isClaiming
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
