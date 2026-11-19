import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

import 'home_screen.dart';
import '../services/biometric_authenticator.dart';
import '../widgets/fliq_wordmark.dart';

class BiometricLockScreen extends StatefulWidget {
  const BiometricLockScreen({required this.authenticator, super.key});

  final BiometricAuthenticator authenticator;

  @override
  State<BiometricLockScreen> createState() => _BiometricLockScreenState();
}

class _BiometricLockScreenState extends State<BiometricLockScreen> {
  bool _isAuthenticating = false;

  Future<void> _unlock() async {
    if (_isAuthenticating) return;
    setState(() => _isAuthenticating = true);

    try {
      final authenticated = await widget.authenticator.authenticate();
      if (!mounted) return;
      if (authenticated) {
        unawaited(
          Navigator.of(context).pushAndRemoveUntil<void>(
            MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
            (_) => false,
          ),
        );
        return;
      }
      _showMessage('Authentication was not completed.');
    } on LocalAuthException catch (error) {
      if (!mounted) return;
      debugPrint('Biometric authentication failed: $error');
      _showMessage(_messageFor(error.code));
    } on PlatformException catch (error) {
      if (!mounted) return;
      debugPrint('Biometric authentication failed: $error');
      _showMessage('Biometric unlock is unavailable. Please try again.');
    } finally {
      if (mounted) setState(() => _isAuthenticating = false);
    }
  }

  String _messageFor(LocalAuthExceptionCode code) {
    return switch (code) {
      LocalAuthExceptionCode.noCredentialsSet ||
      LocalAuthExceptionCode.noBiometricsEnrolled ||
      LocalAuthExceptionCode.noBiometricHardware =>
        'Set up biometrics or a device passcode to unlock Fliq.',
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

  @override
  Widget build(BuildContext context) {
    const buttonLabel = 'Unlock with biometrics';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const FliqWordmark(),
                        const SizedBox(height: 24),
                        const Text(
                          'fliq is locked',
                          style: TextStyle(
                            color: Color(0xFFA8A8A8),
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  height: 80,
                  child: FilledButton(
                    key: const ValueKey('biometric-unlock'),
                    onPressed: _isAuthenticating ? null : _unlock,
                    style: FilledButton.styleFrom(
                      foregroundColor: Colors.black,
                      backgroundColor: Colors.white,
                      disabledBackgroundColor: Colors.white,
                      disabledForegroundColor: Colors.black54,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: _isAuthenticating
                        ? const SizedBox(
                            width: 23,
                            height: 23,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.fingerprint_rounded),
                              const SizedBox(width: 12),
                              Text(
                                buttonLabel,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.25,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
