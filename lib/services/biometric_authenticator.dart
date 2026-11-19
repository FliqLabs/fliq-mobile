import 'package:local_auth/local_auth.dart';

abstract interface class BiometricAuthenticator {
  Future<bool> authenticate();
}

class LocalBiometricAuthenticator implements BiometricAuthenticator {
  const LocalBiometricAuthenticator();

  @override
  Future<bool> authenticate() {
    return LocalAuthentication().authenticate(
      localizedReason: 'Unlock Fliq to access your account.',
      persistAcrossBackgrounding: true,
    );
  }
}
