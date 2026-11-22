/// The best after-fee rate for 1 token, from GET /rates/{token}/{currency}.
class Rate {
  const Rate({
    required this.rate,
    required this.rateBeforeFees,
    required this.provider,
    required this.providersQuoting,
  });

  /// Local money per 1 token after fees, e.g. 1432.89 naira per 1 USDC.
  final double rate;
  final double rateBeforeFees;
  final String provider;
  final int providersQuoting;

  /// Builds a Rate from the server's JSON reply.
  factory Rate.fromJson(Map<String, dynamic> json) {
    return Rate(
      rate: (json['rate'] as num).toDouble(),
      rateBeforeFees: (json['rate_before_fees'] as num).toDouble(),
      provider: json['provider'] as String,
      providersQuoting: json['providers_quoting'] as int,
    );
  }
}
