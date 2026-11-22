import 'package:flutter/material.dart';

import 'screens/biometric_lock_screen.dart';
import 'screens/welcome_screen.dart';
import 'services/account_store.dart';
import 'services/biometric_authenticator.dart';
import 'theme/app_theme.dart';

class FliqApp extends StatelessWidget {
  const FliqApp({
    super.key,
    this.biometricAuthenticator = const LocalBiometricAuthenticator(),
  });

  final BiometricAuthenticator biometricAuthenticator;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'fliq',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      // A saved session opens at the lock screen; otherwise at Welcome.
      home: AccountStore.instance.isSignedIn
          ? BiometricLockScreen(authenticator: biometricAuthenticator)
          : WelcomeScreen(biometricAuthenticator: biometricAuthenticator),
    );
  }
}
