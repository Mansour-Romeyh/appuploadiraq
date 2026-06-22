import 'package:flutter/material.dart';

/// Dark theme palette ported from the law-firm-app (constants/colors.ts).
abstract final class AppColors {
  static const Color text = Color(0xFFF5F0E8);
  static const Color tint = Color(0xFFC9A84C);
  static const Color background = Color(0xFF0D0D0D);
  static const Color foreground = Color(0xFFF5F0E8);
  static const Color card = Color(0xFF1A1A1A);
  static const Color cardForeground = Color(0xFFF5F0E8);
  static const Color primary = Color(0xFFC9A84C);
  static const Color primaryForeground = Color(0xFF0D0D0D);
  static const Color secondary = Color(0xFFC9A84C);
  static const Color secondaryForeground = Color(0xFF0D0D0D);
  static const Color muted = Color(0xFF242424);
  static const Color mutedForeground = Color(0xFF888888);
  static const Color accent = Color(0xFFC9A84C);
  static const Color accentForeground = Color(0xFF0D0D0D);
  static const Color destructive = Color(0xFFC0392B);
  static const Color destructiveForeground = Color(0xFFFFFFFF);
  static const Color border = Color(0xFF2A2A2A);
  static const Color input = Color(0xFF2A2A2A);
  static const Color gold = Color(0xFFC9A84C);
  static const Color goldLight = Color(0xFF2A2210);
  static const Color navy = Color(0xFF0D0D0D);
  static const Color navyLight = Color(0xFF1A1A1A);
  static const Color cream = Color(0xFFF5F0E8);
  static const Color success = Color(0xFF27AE60);
  static const Color warning = Color(0xFFF39C12);

  static const double radius = 10;
}

/// Mimics the `color + "18"` hex-alpha suffix pattern from the RN app.
extension HexAlpha on Color {
  Color withHexAlpha(String hex) => withAlpha(int.parse(hex, radix: 16));
}
