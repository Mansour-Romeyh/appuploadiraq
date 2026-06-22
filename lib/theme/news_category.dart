import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Stable (non-localized) Arabic category key → accent color. The backend's
/// `category` field is this key; the displayed label is the localized
/// `categoryLabel`. Mirrors the reference app's `categoryColors` map.
const Map<String, Color> newsCategoryColors = {
  'تشريعات': Color(0xFF1565C0),
  'أخبار قانونية': Color(0xFF2E7D32),
  'توعية': Color(0xFFF57F17),
  'استثمار': Color(0xFF6A1B9A),
};

Color newsCategoryColor(String category) =>
    newsCategoryColors[category] ?? AppColors.secondary;
