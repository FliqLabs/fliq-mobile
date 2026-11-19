import 'package:flutter/material.dart';

import '../models/crypto.dart';

/// Round coloured badge for a network (NEAR, Monad, Base, …).
class NetworkBadge extends StatelessWidget {
  const NetworkBadge({required this.network, this.size = 36, super.key});

  final CryptoNetwork network;
  final double size;

  @override
  Widget build(BuildContext context) {
    final isNear = network.name == 'NEAR';
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isNear ? Colors.transparent : network.color,
        shape: BoxShape.circle,
      ),
      child: Text(
        network.badge,
        style: TextStyle(
          color: isNear ? network.color : Colors.white,
          fontSize: size * (isNear ? 0.72 : 0.42),
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
    );
  }
}

/// Round coloured icon for a coin (USDC, USDT, BTC).
class AssetIcon extends StatelessWidget {
  const AssetIcon({required this.asset, this.size = 28, super.key});

  final CryptoAsset asset;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (asset.symbol == 'BTC') {
      return Icon(asset.icon, color: asset.color, size: size);
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: asset.color, shape: BoxShape.circle),
      child: Icon(asset.icon, color: Colors.white, size: size * 0.66),
    );
  }
}

/// Bitcoin logo with a small purple "B" badge, used for transactions.
class TransactionCoinIcon extends StatelessWidget {
  const TransactionCoinIcon({this.size = 40, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            Icons.currency_bitcoin_rounded,
            color: const Color(0xFFF7931A),
            size: size * 0.9,
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: size * 0.42,
              height: size * 0.42,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Color(0xFF7B3FE4),
                shape: BoxShape.circle,
              ),
              child: Text(
                'B',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size * 0.22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
