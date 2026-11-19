/// Small text-formatting helpers shared across screens.
library;

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// Adds thousands separators: `1462.5` → `1,462.50` (with [decimals] = 2).
String groupDigits(num value, {int decimals = 0}) {
  final fixed = value.abs().toStringAsFixed(decimals);
  final parts = fixed.split('.');
  final whole = parts.first;
  final buffer = StringBuffer(value < 0 ? '-' : '');
  for (var i = 0; i < whole.length; i++) {
    if (i > 0 && (whole.length - i) % 3 == 0) buffer.write(',');
    buffer.write(whole[i]);
  }
  if (parts.length > 1) buffer.write('.${parts[1]}');
  return buffer.toString();
}

/// `₦5,000` or `₦1,452.10` with [decimals].
String formatNaira(num value, {int decimals = 0}) =>
    '₦${groupDigits(value, decimals: decimals)}';

/// `$3.44`.
String formatUsd(num value, {int decimals = 2}) =>
    '\$${groupDigits(value, decimals: decimals)}';

String _twoDigits(int n) => n.toString().padLeft(2, '0');

/// `9:09` (24-hour, no leading zero on the hour).
String formatShortTime(DateTime time) =>
    '${time.hour}:${_twoDigits(time.minute)}';

/// `15 Nov 2026`.
String formatDay(DateTime time) =>
    '${time.day} ${_months[time.month - 1]} ${time.year}';

/// `15 Nov at 09:09`.
String formatDayAndTime(DateTime time) =>
    '${time.day} ${_months[time.month - 1]} at '
    '${_twoDigits(time.hour)}:${_twoDigits(time.minute)}';

/// Countdown shown as total minutes and seconds, e.g. `4,329:57`.
String formatCountdown(Duration remaining) {
  final minutes = remaining.inMinutes;
  final seconds = remaining.inSeconds % 60;
  return '${groupDigits(minutes)}:${_twoDigits(seconds)}';
}

/// Shortens long addresses: `olayinka05.fliqaccount.near` → `olayinka…near`.
String shortenAddress(String address, {int head = 8, int tail = 5}) {
  if (address.length <= head + tail + 1) return address;
  return '${address.substring(0, head)}…'
      '${address.substring(address.length - tail)}';
}
