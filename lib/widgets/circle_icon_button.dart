import 'package:flutter/material.dart';

/// A round, outlined icon button used in screen headers.
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.size = 48,
    this.borderColor = const Color(0xFF383838),
    super.key,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final double size;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: size,
        height: size,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            padding: EdgeInsets.zero,
            shape: const CircleBorder(),
            side: BorderSide(color: borderColor),
          ),
          child: Icon(icon, size: 21),
        ),
      ),
    );
  }
}
