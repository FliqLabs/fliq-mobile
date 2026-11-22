import 'package:flutter/material.dart';

/// The fliq app icon as the welcome screen shows it: rounded, with a faint
/// border, like the iPhone app's FliqMark.
class FliqLogo extends StatelessWidget {
  const FliqLogo({super.key, this.size = 52});

  final double size;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size / 4);
    return Container(
      width: size,
      height: size,
      foregroundDecoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: const Color(0x24FFFFFF)),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Image.asset(
          'assets/icon/app_icon.png',
          fit: BoxFit.cover,
          cacheWidth: (size * 4).round(),
          semanticLabel: 'fliq',
        ),
      ),
    );
  }
}
