import 'dart:convert';
import 'dart:typed_data';

/// NEAR's text form of keys and hashes: base58 with Bitcoin's alphabet.
abstract final class Base58 {
  static const _alphabet =
      '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';

  static String encode(List<int> bytes) {
    final digits = <int>[];
    for (final byte in bytes) {
      var carry = byte;
      for (var i = 0; i < digits.length; i++) {
        carry += digits[i] << 8;
        digits[i] = carry % 58;
        carry ~/= 58;
      }
      while (carry > 0) {
        digits.add(carry % 58);
        carry ~/= 58;
      }
    }
    final zeros = bytes.takeWhile((b) => b == 0).length;
    return '1' * zeros + digits.reversed.map((d) => _alphabet[d]).join();
  }

  /// Null when the text has a character outside the alphabet.
  static Uint8List? decode(String text) {
    final bytes = <int>[];
    for (final char in text.split('')) {
      var carry = _alphabet.indexOf(char);
      if (carry < 0) return null;
      for (var i = 0; i < bytes.length; i++) {
        carry += bytes[i] * 58;
        bytes[i] = carry & 0xff;
        carry >>= 8;
      }
      while (carry > 0) {
        bytes.add(carry & 0xff);
        carry >>= 8;
      }
    }
    final zeros = text.split('').takeWhile((c) => c == '1').length;
    return Uint8List.fromList([...List.filled(zeros, 0), ...bytes.reversed]);
  }
}

/// `ed25519:<base58>` public keys, as NEAR writes them.
abstract final class NearKey {
  static String encode(List<int> publicKey) =>
      'ed25519:${Base58.encode(publicKey)}';

  /// The raw 32 bytes, or null when [text] isn't an ed25519 key.
  static Uint8List? decode(String text) {
    if (!text.startsWith('ed25519:')) return null;
    final raw = Base58.decode(text.substring('ed25519:'.length));
    return raw != null && raw.length == 32 ? raw : null;
  }
}

/// Little-endian Borsh, enough for a delegate action.
class BorshWriter {
  final _bytes = BytesBuilder(copy: false);

  Uint8List get bytes => _bytes.toBytes();

  void u8(int value) => _bytes.addByte(value & 0xff);

  void u32(int value) {
    final data = ByteData(4)..setUint32(0, value, Endian.little);
    _bytes.add(data.buffer.asUint8List());
  }

  void u64(BigInt value) => _unsigned(value, 8);

  void u128(BigInt value) => _unsigned(value, 16);

  void raw(List<int> bytes) => _bytes.add(bytes);

  /// Length-prefixed bytes.
  void bytesWithLength(List<int> bytes) {
    u32(bytes.length);
    _bytes.add(bytes);
  }

  void string(String value) => bytesWithLength(utf8.encode(value));

  void _unsigned(BigInt value, int length) {
    if (value.isNegative || value.bitLength > length * 8) {
      throw ArgumentError.value(
        value,
        'value',
        'does not fit in $length bytes',
      );
    }
    var rest = value;
    final mask = BigInt.from(0xff);
    for (var i = 0; i < length; i++) {
      _bytes.addByte((rest & mask).toInt());
      rest = rest >> 8;
    }
  }
}

/// USDC has 6 decimals. Turns "50.00" into 50000000 exactly, never through
/// a float.
BigInt usdcUnits(String decimal) {
  final trimmed = decimal.trim();
  final match = RegExp(r'^(\d+)(?:\.(\d{1,6}))?$').firstMatch(trimmed);
  if (match == null) {
    throw FormatException('Not a USDC amount: $decimal');
  }
  final whole = BigInt.parse(match.group(1)!);
  final fraction = (match.group(2) ?? '').padRight(6, '0');
  return whole * BigInt.from(1000000) + BigInt.parse(fraction);
}
