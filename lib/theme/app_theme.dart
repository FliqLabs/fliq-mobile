import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const background = Colors.black;

  static final dark = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    useMaterial3: true,
  );
}
