/// A bank or mobile-money provider, from `GET /institutions`.
class Institution {
  const Institution({required this.code, required this.name});

  factory Institution.fromJson(Map<String, dynamic> json) =>
      Institution(code: json['code'] as String, name: json['name'] as String);

  /// e.g. "058" for GTBank.
  final String code;
  final String name;
}

/// A saved account, from `GET /recipients`. The full number is never sent
/// back, only its last four digits.
class Recipient {
  const Recipient({
    required this.id,
    required this.accountName,
    required this.bankName,
    required this.last4,
    this.own = false,
  });

  factory Recipient.fromJson(Map<String, dynamic> json) {
    final bank = json['bank'] as Map<String, dynamic>? ?? const {};
    return Recipient(
      id: json['recipient_id'] as String,
      accountName: json['account_name'] as String,
      bankName: bank['name'] as String? ?? '',
      last4: json['account_last4'] as String,
      own: json['own'] as bool? ?? false,
    );
  }

  final String id;
  final String accountName;
  final String bankName;
  final String last4;

  /// The user's own account, listed under "Yours".
  final bool own;
}

/// The daily limit on what may leave the vault, from `GET /me/limits`.
/// All amounts are US dollars.
class Limits {
  const Limits({
    this.dailyLimit,
    this.spentToday = 0,
    this.pendingLimit,
    this.pendingAt,
  });

  factory Limits.fromJson(Map<String, dynamic> json) {
    final pending = json['pending'] as Map<String, dynamic>?;
    double? amount(Object? value) =>
        value == null ? null : double.tryParse(value.toString());
    return Limits(
      dailyLimit: amount(json['daily_limit']),
      spentToday: amount(json['spent_today']) ?? 0,
      pendingLimit: amount(pending?['daily_limit']),
      pendingAt: pending?['effective_at'] == null
          ? null
          : DateTime.tryParse(pending!['effective_at'] as String)?.toLocal(),
    );
  }

  /// Null when no limit is set.
  final double? dailyLimit;
  final double spentToday;

  /// A raised limit waiting its 24 hours, if any.
  final double? pendingLimit;
  final DateTime? pendingAt;

  bool get isSet => dailyLimit != null;
  bool get hasPendingRaise => pendingAt != null;
}

/// A device signed in to the account, from `GET /sessions`.
class DeviceSession {
  const DeviceSession({
    required this.id,
    required this.device,
    required this.current,
    required this.lastActiveAt,
  });

  factory DeviceSession.fromJson(Map<String, dynamic> json) => DeviceSession(
    id: json['session_id'] as String,
    device: json['device'] as String? ?? 'Unknown device',
    current: json['current'] as bool? ?? false,
    lastActiveAt:
        DateTime.tryParse(json['last_active_at'] as String? ?? '')?.toLocal() ??
        DateTime.now(),
  );

  final String id;
  final String device;

  /// This phone.
  final bool current;
  final DateTime lastActiveAt;
}
