import 'package:flutter/material.dart';

import 'screens/welcome_screen.dart';
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
      title: 'Fliq',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: WelcomeScreen(biometricAuthenticator: biometricAuthenticator),
    );
  }
}
