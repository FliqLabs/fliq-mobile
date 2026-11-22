import 'package:flutter/material.dart';

/// The official logos, copied from the fliq iPhone app's assets.
abstract final class Logos {
  static const _chains = {
    'arbitrum',
    'base',
    'bnb',
    'ethereum',
    'near',
    'optimism',
    'polygon',
    'solana',
    'tron',
  };

  /// A network's logo, e.g. "BNB Smart Chain" → `chains/bnb.png`. Null when
  /// there isn't one (Monad), so callers draw their own badge.
  static String? chain(String networkName) {
    if (networkName == 'Bitcoin') return token('BTC');
    final id = networkName == 'BNB Smart Chain'
        ? 'bnb'
        : networkName.toLowerCase();
    return _chains.contains(id) ? 'assets/logos/chains/$id.png' : null;
  }

  /// `USDC`, `USDT`, `BTC`.
  static String? token(String symbol) => switch (symbol.toUpperCase()) {
    'USDC' => 'assets/logos/tokens/usdc.png',
    'USDT' => 'assets/logos/tokens/usdt.png',
    'BTC' => 'assets/logos/tokens/btc.png',
    // A coin's logo is its own chain's logo.
    'BNB' => 'assets/logos/chains/bnb.png',
    'ETH' => 'assets/logos/chains/ethereum.png',
    'SOL' => 'assets/logos/chains/solana.png',
    _ => null,
  };

  /// A bank by its API `logo_key`, e.g. `gtbank`, `access-bank`.
  static String bank(String logoKey) => 'assets/logos/banks/$logoKey.png';
}

/// A few overlapping round logos and "+6", the way the best wallets show
/// what a row covers before it is opened. Same as the iPhone app's LogoStack.
class LogoStack extends StatelessWidget {
  const LogoStack({
    required this.images,
    this.extra = 0,
    this.size = 22,
    this.whiteBehind = false,
    this.ringColor = const Color(0xFF1B1B1D),
    super.key,
  });

  final List<String> images;
  final int extra;
  final double size;

  /// Bank logos sit on white, as they're drawn for light backgrounds.
  final bool whiteBehind;
  final Color ringColor;

  @override
  Widget build(BuildContext context) {
    final step = size * 0.68;
    return ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: step * (images.length - 1) + size,
            height: size,
            child: Stack(
              children: [
                // Drawn last-first so the first logo sits on top.
                for (var i = images.length - 1; i >= 0; i--)
                  Positioned(
                    left: step * i,
                    child: Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: whiteBehind ? Colors.white : Colors.transparent,
                        border: Border.all(color: ringColor, width: 1.5),
                      ),
                      child: ClipOval(
                        child: Image.asset(images[i], fit: BoxFit.cover),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (extra > 0) ...[
            const SizedBox(width: 6),
            Text(
              '+$extra',
              style: const TextStyle(
                color: Color(0xFF9A9A9E),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
