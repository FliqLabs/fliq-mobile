/// Shared rules for typing a money amount on an on-screen keypad.
///
/// [current] is the amount typed so far (e.g. `'0'`, `'12.5'`) and [key] is
/// the key that was tapped: a digit `'0'`–`'9'`, `'.'`, or `'delete'`.
/// Returns the new amount string.
///
/// Rules:
/// - The amount never becomes empty; it falls back to `'0'`.
/// - Only one decimal point is allowed, with at most [maxDecimals] digits
///   after it.
/// - The whole string is capped at [maxLength] characters.
String applyAmountKey(
  String current,
  String key, {
  int maxLength = 10,
  int maxDecimals = 2,
}) {
  if (key == 'delete') {
    if (current.length <= 1) return '0';
    final next = current.substring(0, current.length - 1);
    return next == '0.' ? '0' : next;
  }

  if (key == '.') {
    if (current.contains('.') || current.length >= maxLength) return current;
    return '$current.';
  }

  if (current == '0') return key;

  final decimalIndex = current.indexOf('.');
  if (decimalIndex >= 0 && current.length - decimalIndex > maxDecimals) {
    return current;
  }
  if (current.length >= maxLength) return current;
  return current + key;
}
