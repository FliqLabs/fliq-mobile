import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../services/biometric_authenticator.dart';
import 'near_format.dart';

/// Thrown when the user didn't pass biometrics, so nothing was signed.
class SigningCancelled implements Exception {
  const SigningCancelled();
}

/// The ed25519 key that owns the user's NEAR account. It is made on this
/// phone and never leaves it. A passkey can't be this key: passkeys are P-256
/// and NEAR keys are ed25519.
abstract interface class DeviceKeys {
  /// `ed25519:<base58>`. Made on first use.
  Future<String> publicKey();

  /// Asks for biometrics, then signs each message.
  Future<List<Uint8List>> sign(
    List<Uint8List> messages, {
    required String reason,
  });
}

/// Keeps the key's 32-byte seed in the Android Keystore (or iOS Keychain)
/// through flutter_secure_storage, and asks for biometrics before every
/// signature.
class SecureDeviceKeys implements DeviceKeys {
  SecureDeviceKeys({
    FlutterSecureStorage? storage,
    this.authenticator = const LocalBiometricAuthenticator(),
  }) : _storage = storage ?? const FlutterSecureStorage();

  static const _seedKey = 'fliq.device-key.seed';
  static const _publicKey = 'fliq.device-key.public';

  final FlutterSecureStorage _storage;
  final BiometricAuthenticator authenticator;
  final _ed25519 = Ed25519();

  @override
  Future<String> publicKey() async {
    final saved = await _storage.read(key: _publicKey);
    if (saved != null && await _storage.read(key: _seedKey) != null) {
      return saved;
    }
    final seed = Uint8List.fromList(SecretKeyData.random(length: 32).bytes);
    final pair = await _ed25519.newKeyPairFromSeed(seed);
    final public = NearKey.encode((await pair.extractPublicKey()).bytes);
    await _storage.write(key: _seedKey, value: base64Encode(seed));
    await _storage.write(key: _publicKey, value: public);
    return public;
  }

  @override
  Future<List<Uint8List>> sign(
    List<Uint8List> messages, {
    required String reason,
  }) async {
    if (!await authenticator.authenticate()) throw const SigningCancelled();
    final seed = await _storage.read(key: _seedKey);
    if (seed == null) throw StateError('This phone has no signing key yet.');
    return signWithSeed(base64Decode(seed), messages);
  }
}

/// Signs with a known seed. Shared by the real keys and by tests.
Future<List<Uint8List>> signWithSeed(
  List<int> seed,
  List<Uint8List> messages,
) async {
  final ed25519 = Ed25519();
  final pair = await ed25519.newKeyPairFromSeed(seed);
  return [
    for (final message in messages)
      Uint8List.fromList((await ed25519.sign(message, keyPair: pair)).bytes),
  ];
}

/// The public key for a known seed, `ed25519:<base58>`.
Future<String> publicKeyForSeed(List<int> seed) async {
  final pair = await Ed25519().newKeyPairFromSeed(seed);
  return NearKey.encode((await pair.extractPublicKey()).bytes);
}

/// A key that lives only in memory. For tests.
class MemoryDeviceKeys implements DeviceKeys {
  MemoryDeviceKeys(this.seed);

  final List<int> seed;
  int signatures = 0;

  @override
  Future<String> publicKey() => publicKeyForSeed(seed);

  @override
  Future<List<Uint8List>> sign(
    List<Uint8List> messages, {
    required String reason,
  }) async {
    signatures += messages.length;
    return signWithSeed(seed, messages);
  }
}
