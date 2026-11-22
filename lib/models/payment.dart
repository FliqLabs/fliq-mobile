/// A bank account the bank confirmed, from `POST /accounts/verify`.
class VerifiedAccount {
  const VerifiedAccount({
    required this.bankCode,
    required this.number,
    required this.accountName,
    required this.institution,
    this.nameVerified = true,
  });

  factory VerifiedAccount.fromJson(Map<String, dynamic> json) =>
      VerifiedAccount(
        bankCode: json['bank'] as String,
        number: json['number'] as String,
        accountName: json['account_name'] as String,
        institution: json['institution'] as String? ?? '',
        nameVerified: json['name_verified'] as bool? ?? true,
      );

  final String bankCode;
  final String number;

  /// The name the bank has on the account, e.g. "DARA OKONKWO".
  final String accountName;

  /// The bank's name, e.g. "GTBank".
  final String institution;

  /// False when the bank couldn't look the name up.
  final bool nameVerified;

  String get last4 =>
      number.length > 4 ? number.substring(number.length - 4) : number;
}

/// One provider's offer inside a quote.
class QuoteRoute {
  const QuoteRoute({
    required this.provider,
    required this.status,
    required this.routed,
    this.rate,
  });

  factory QuoteRoute.fromJson(Map<String, dynamic> json) => QuoteRoute(
    provider: json['provider'] as String,
    status: json['status'] as String? ?? 'live',
    routed: json['routed'] as bool? ?? false,
    rate: (json['rate'] as num?)?.toDouble(),
  );

  final String provider;

  /// `live`, `stale` or `paused`.
  final String status;
  final bool routed;
  final double? rate;
}

/// The best after-fee price for one payout, from `POST /quotes`.
class Quote {
  const Quote({
    required this.quoteId,
    required this.currency,
    required this.amountUsd,
    required this.rate,
    required this.rateBeforeFees,
    required this.feesMinor,
    required this.receive,
    required this.provider,
    required this.bestOf,
    required this.expiresIn,
    this.routes = const [],
  });

  factory Quote.fromJson(Map<String, dynamic> json) {
    final fees = json['fees'] as Map<String, dynamic>? ?? const {};
    return Quote(
      quoteId: json['quote_id'] as String,
      currency: (json['currency'] as String).toUpperCase(),
      amountUsd: double.parse(json['amount'] as String),
      rate: (json['rate'] as num).toDouble(),
      rateBeforeFees: (json['rate_before_fees'] as num).toDouble(),
      feesMinor: (fees['total'] as num?)?.toInt() ?? 0,
      receive: (json['receive'] as num).toDouble(),
      provider: json['provider'] as String,
      bestOf: json['best_of'] as int? ?? 1,
      expiresIn: json['expires_in'] as int? ?? 90,
      routes: [
        for (final route in json['routes'] as List<dynamic>? ?? const [])
          QuoteRoute.fromJson(route as Map<String, dynamic>),
      ],
    );
  }

  final String quoteId;

  /// `NGN` or `KES`.
  final String currency;

  /// Dollars that leave the vault.
  final double amountUsd;

  /// Local money per dollar after fees.
  final double rate;
  final double rateBeforeFees;

  /// All fees in the smallest local unit (kobo, cents). 34400 = ₦344.
  final int feesMinor;

  /// What the recipient gets, in local money.
  final double receive;
  final String provider;

  /// How many providers were asked.
  final int bestOf;

  /// Seconds the rate is held.
  final int expiresIn;
  final List<QuoteRoute> routes;

  double get fees => feesMinor / 100;

  /// How much more the recipient gets than with the next best provider.
  double? get beatsNextBy {
    final others = routes
        .where((r) => !r.routed && r.rate != null && r.status == 'live')
        .map((r) => r.rate!)
        .toList();
    if (others.isEmpty) return null;
    others.sort();
    final next = others.last;
    return ((rate - next) * amountUsd).roundToDouble();
  }
}

/// Another fliq user, from `GET /people/{name}`.
class Person {
  const Person({required this.nearAccount, this.displayName, this.photoUrl});

  factory Person.fromJson(Map<String, dynamic> json) => Person(
    nearAccount: json['near_account'] as String,
    displayName: json['display_name'] as String?,
    photoUrl: json['photo_url'] as String?,
  );

  final String nearAccount;
  final String? displayName;
  final String? photoUrl;

  String get handle => nearAccount.split('.').first;
}

/// Pretty names for payout providers.
String providerName(String id) => switch (id) {
  'paycrest' => 'Paycrest',
  'busha' => 'Busha',
  'fonbnk' => 'Fonbnk',
  'bitnob' => 'Bitnob',
  'paj' => 'Paj',
  _ => id.isEmpty ? id : id[0].toUpperCase() + id.substring(1),
};

/// What `POST /relays` says about a signed transfer.
class RelayResult {
  const RelayResult({
    required this.status,
    required this.delegateHash,
    this.txHash,
    this.failures = const [],
  });

  factory RelayResult.fromJson(Map<String, dynamic> json) => RelayResult(
    status: json['status'] as String,
    delegateHash: json['delegate_hash'] as String,
    txHash: json['tx_hash'] as String?,
    failures: [
      for (final failure in json['failures'] as List<dynamic>? ?? const [])
        failure.toString(),
    ],
  );

  /// `succeeded`, `failed` or `pending`.
  final String status;
  final String delegateHash;
  final String? txHash;
  final List<String> failures;

  bool get isPending => status == 'pending';
  bool get succeeded => status == 'succeeded';
}

/// A cash-out to a bank or mobile-money account, from `/payouts`.
class Payout {
  const Payout({
    required this.payoutId,
    required this.state,
    required this.accountName,
    required this.amountUsd,
    required this.receive,
    required this.currency,
    required this.rate,
    required this.provider,
    required this.depositChain,
    required this.depositAddress,
    required this.depositAmount,
    this.bankReference,
    this.seconds,
  });

  factory Payout.fromJson(Map<String, dynamic> json) {
    final deposit = json['deposit'] as Map<String, dynamic>? ?? const {};
    return Payout(
      payoutId: json['payout_id'] as String,
      state: json['state'] as String,
      accountName: json['account_name'] as String? ?? '',
      amountUsd: double.tryParse(json['amount'].toString()) ?? 0,
      receive: (json['receive'] as num?)?.toDouble() ?? 0,
      currency: (json['currency'] as String? ?? 'ngn').toUpperCase(),
      rate: (json['rate'] as num?)?.toDouble() ?? 0,
      provider: json['provider'] as String? ?? '',
      depositChain: deposit['chain'] as String? ?? '',
      depositAddress: deposit['address'] as String? ?? '',
      depositAmount: deposit['amount']?.toString() ?? '0',
      bankReference: json['bank_reference'] as String?,
      seconds: json['seconds'] as int?,
    );
  }

  final String payoutId;

  /// e.g. `awaiting_deposit`, `paying_out`, `settled`, `refunded`.
  final String state;
  final String accountName;
  final double amountUsd;
  final double receive;
  final String currency;
  final double rate;
  final String provider;

  /// Where the vault must send the USDC for this order.
  final String depositChain;
  final String depositAddress;
  final String depositAmount;

  /// The bank's own reference (NIP session in Nigeria), once paid.
  final String? bankReference;

  /// How long the payout took, once paid.
  final int? seconds;

  bool get isPaid => state == 'settled';
  bool get isRefunded => state == 'refunded' || state == 'refunding';
  bool get hasFailed =>
      const {'failed', 'expired', 'refused', 'not_received'}.contains(state);
  bool get isFinished => isPaid || isRefunded || hasFailed;
}

/// Whether a fliq name can be claimed, from `GET /names/{name}`.
class NameAvailability {
  const NameAvailability({required this.available, this.reason});

  factory NameAvailability.fromJson(Map<String, dynamic> json) =>
      NameAvailability(
        available: json['available'] as bool? ?? false,
        reason: json['reason'] as String?,
      );

  final bool available;

  /// `taken`, `invalid` or `reserved`.
  final String? reason;
}

/// Lowercase letters, digits and single hyphens, 2 to 32 long, no hyphen at
/// either end. Null when [raw] isn't a valid fliq name.
String? validFliqName(String raw) {
  final name = raw.trim().toLowerCase().replaceFirst('@', '');
  final ok =
      RegExp(r'^[a-z0-9-]{2,32}$').hasMatch(name) &&
      !name.startsWith('-') &&
      !name.endsWith('-') &&
      !name.contains('--');
  return ok ? name : null;
}
