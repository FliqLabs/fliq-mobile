import 'package:flutter/material.dart';

class FliqSymbol extends StatelessWidget {
  const FliqSymbol({super.key, this.size = 20});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/fliq_symbol_green.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      semanticLabel: 'Fliq',
    );
  }
}
