import 'package:flutter/material.dart';

/// A 3×4 numeric keypad (1–9, `.`, 0, delete) that fills its parent.
///
/// Each key gets a `ValueKey('$keyPrefix-<key>')`, for example
/// `send-key-5` or `send-key-delete`, so tests can tap individual keys.
class AmountKeypad extends StatelessWidget {
  const AmountKeypad({
    required this.onKeyTap,
    required this.keyPrefix,
    this.gridKey,
    this.fontSize = 29,
    this.iconSize = 25,
    this.borderRadius = 36,
    this.fallbackAspectRatio = 1.35,
    super.key,
  });

  /// Called with `'0'`–`'9'`, `'.'` or `'delete'`.
  final ValueChanged<String> onKeyTap;
  final String keyPrefix;
  final Key? gridKey;
  final double fontSize;
  final double iconSize;
  final double borderRadius;
  final double fallbackAspectRatio;

  static const keys = [
    '1', '2', '3', //
    '4', '5', '6', //
    '7', '8', '9', //
    '.', '0', 'delete',
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = constraints.maxWidth / 3;
        final itemHeight = constraints.maxHeight / 4;
        final aspectRatio = itemHeight > 0
            ? itemWidth / itemHeight
            : fallbackAspectRatio;

        return GridView.builder(
          key: gridKey,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: keys.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: aspectRatio,
          ),
          itemBuilder: (context, index) {
            final key = keys[index];
            return InkWell(
              key: ValueKey('$keyPrefix-$key'),
              onTap: () => onKeyTap(key),
              borderRadius: BorderRadius.circular(borderRadius),
              child: Center(
                child: key == 'delete'
                    ? Icon(
                        Icons.backspace_outlined,
                        color: Colors.white,
                        size: iconSize,
                        semanticLabel: 'Delete',
                      )
                    : Text(
                        key,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: fontSize,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
              ),
            );
          },
        );
      },
    );
  }
}
