import 'package:flutter/material.dart';

class FliqLogo extends StatelessWidget {
  const FliqLogo({super.key, this.size = 52});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xD9080911),
        borderRadius: BorderRadius.circular(size * 0.25),
        border: Border.all(color: const Color(0xFF303039)),
      ),
      padding: EdgeInsets.all(size * 0.08),
      child: Image.asset(
        'assets/images/fliq_logo.png',
        fit: BoxFit.contain,
        semanticLabel: 'Fliq logo',
      ),
    );
  }
}
