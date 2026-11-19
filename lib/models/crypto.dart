import 'package:flutter/material.dart';

/// A blockchain network you can receive coins on.
class CryptoNetwork {
  const CryptoNetwork({
    required this.name,
    required this.arrivalTime,
    required this.color,
    required this.badge,
    this.noFee = false,
  });

  final String name;

  /// How long a deposit usually takes, e.g. "~25s".
  final String arrivalTime;

  /// Brand-ish colour for the round network badge.
  final Color color;

  /// Short text drawn inside the badge, e.g. "N" or "M".
  final String badge;
  final bool noFee;
}

/// A coin you can receive, and which networks it works on.
class CryptoAsset {
  const CryptoAsset({
    required this.symbol,
    required this.name,
    required this.networks,
    required this.minimum,
    required this.color,
    required this.icon,
    this.arrivesAs,
  });

  /// e.g. "USDC".
  final String symbol;

  /// e.g. "Tether USDT".
  final String name;
  final List<CryptoNetwork> networks;

  /// Smallest deposit, keyed by network name, e.g. {'NEAR': '0.01 USDC'}.
  final Map<String, String> minimum;
  final Color color;
  final IconData icon;

  /// What the deposit turns into. Defaults to `1 USDC ≈ $1.00` style.
  final String? arrivesAs;

  /// Bitcoin only has one network, so the app skips the network picker.
  bool get hasSingleNetwork => networks.length == 1;
}
