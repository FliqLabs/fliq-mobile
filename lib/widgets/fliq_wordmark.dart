import 'package:flutter/material.dart';

class FliqWordmark extends StatelessWidget {
  const FliqWordmark({super.key});

  @override
  Widget build(BuildContext context) {
    const wordmark = 'flıq';
    const style = TextStyle(
      color: Colors.white,
      fontSize: 42,
      height: 1,
      fontWeight: FontWeight.w900,
      letterSpacing: -2.6,
    );
    final paragraph = TextPainter(
      text: const TextSpan(text: wordmark, style: style),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final iBounds = paragraph.getBoxesForSelection(
      const TextSelection(baseOffset: 2, extentOffset: 3),
    );
    final iCenter = (iBounds.single.left + iBounds.single.right) / 2;
    const opticalCenterAdjustment = 1.5;

    return SizedBox(
      height: 48,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Text(
            wordmark,
            key: ValueKey('fliq-wordmark'),
            semanticsLabel: 'fliq',
            style: style,
          ),
          Positioned(
            top: -1,
            left: iCenter - 5 - opticalCenterAdjustment,
            child: Container(
              key: const ValueKey('fliq-wordmark-dot'),
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF2529FF),
                    blurRadius: 9,
                    spreadRadius: 2,
                  ),
                ],
                gradient: RadialGradient(
                  colors: [Color(0xFF5F8FFF), Color(0xFF3217FF)],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
