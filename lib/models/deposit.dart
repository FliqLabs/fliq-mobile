/// A coin and chain the vault can be topped up from, from
/// `GET /deposits/sources`.
class DepositSource {
  const DepositSource({
    required this.token,
    required this.chain,
    required this.minimum,
    required this.etaSeconds,
    required this.direct,
    required this.available,
    this.address,
  });

  factory DepositSource.fromJson(Map<String, dynamic> json) => DepositSource(
    token: json['token'] as String,
    chain: json['chain'] as String,
    minimum: json['minimum'] as String? ?? '0',
    etaSeconds: json['eta_seconds'] as int? ?? 0,
    direct: json['direct'] as bool? ?? false,
    available: json['available'] as bool? ?? true,
    address: json['address'] as String?,
  );

  /// e.g. `usdc`, `usdt`, `btc`.
  final String token;

  /// e.g. `near`, `solana`, `bitcoin`.
  final String chain;
  final String minimum;
  final int etaSeconds;

  /// The user's own NEAR account: nothing to reserve, the address is fixed.
  final bool direct;
  final bool available;
  final String? address;
}

/// An address that takes one top-up and lands it in the vault.
class DepositAddress {
  const DepositAddress({
    required this.address,
    required this.minimum,
    this.depositId,
    this.memo,
    this.fee,
    this.reservedUntil,
    this.isDemo = false,
  });

  factory DepositAddress.fromJson(Map<String, dynamic> json) => DepositAddress(
    depositId: json['deposit_id'] as String?,
    address: json['address'] as String,
    memo: json['memo'] as String?,
    minimum: json['minimum'] as String? ?? '0',
    fee: json['fee'] as String?,
    reservedUntil: DateTime.tryParse(json['reserved_until'] as String? ?? '')
        ?.toLocal(),
  );

  final String? depositId;
  final String address;

  /// Some chains need a memo or tag with the transfer.
  final String? memo;

  /// Smallest amount, in the source token.
  final String minimum;

  /// Network and bridge fees in dollars, if any.
  final String? fee;

  /// After this the address is no longer watched. Null never expires.
  final DateTime? reservedUntil;

  /// A made-up address for exploring the app signed out. Never send to it.
  final bool isDemo;

  bool get hasFee => fee != null && (double.tryParse(fee!) ?? 0) > 0;
}

/// A payment request with its public pay link, from `POST /requests`.
class PaymentRequest {
  const PaymentRequest({
    required this.id,
    required this.code,
    required this.link,
    required this.amount,
    this.isDemo = false,
  });

  factory PaymentRequest.fromJson(Map<String, dynamic> json) => PaymentRequest(
    id: json['request_id'] as String,
    code: json['code'] as String,
    link: json['link'] as String,
    amount: double.tryParse(json['amount'] as String? ?? '') ?? 0,
  );

  final String id;
  final String code;

  /// Full https link anyone can pay.
  final String link;
  final double amount;
  final bool isDemo;
}
