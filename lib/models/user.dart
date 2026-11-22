/// The signed-in person, from `GET /me`.
class User {
  const User({
    required this.userId,
    this.nearAccount,
    this.displayName,
    this.photoUrl,
    this.vault,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
    userId: json['user_id'] as String,
    nearAccount: json['near_account'] as String?,
    displayName: json['display_name'] as String?,
    photoUrl: json['photo_url'] as String?,
    vault: json['vault'] as String?,
  );

  final String userId;

  /// e.g. `olayinka05.fliqaccount.near`. Null until a fliq name is claimed.
  final String? nearAccount;
  final String? displayName;
  final String? photoUrl;
  final String? vault;

  bool get hasName => nearAccount != null;

  /// The fliq name without the NEAR suffix, e.g. `olayinka05`.
  String? get handle => nearAccount?.split('.').first;

  /// Up to two letters for the avatar, from the display name or handle.
  String get initials {
    final source = (displayName?.trim().isNotEmpty ?? false)
        ? displayName!.trim()
        : (handle ?? '?');
    final words = source.split(RegExp(r'\s+'));
    final letters = words.length > 1
        ? '${words[0][0]}${words[1][0]}'
        : source.substring(0, source.length >= 2 ? 2 : 1);
    return letters.toUpperCase();
  }
}

/// What `/auth/.../verify` and `/auth/refresh` return.
class Session {
  const Session({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.user,
  });

  factory Session.fromJson(Map<String, dynamic> json) => Session(
    accessToken: json['access_token'] as String,
    refreshToken: json['refresh_token'] as String,
    expiresIn: json['expires_in'] as int,
    user: User.fromJson(json['user'] as Map<String, dynamic>),
  );

  final String accessToken;
  final String refreshToken;

  /// Seconds until the access token expires.
  final int expiresIn;
  final User user;
}

/// The vault balance in US dollars, from `GET /vault`.
class VaultBalance {
  const VaultBalance({required this.available, required this.total});

  factory VaultBalance.fromJson(Map<String, dynamic> json) => VaultBalance(
    available: double.parse(json['available'] as String),
    total: double.parse(json['total'] as String),
  );

  static const empty = VaultBalance(available: 0, total: 0);

  /// What can be spent right now.
  final double available;
  final double total;
}
