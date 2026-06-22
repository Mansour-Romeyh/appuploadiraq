import 'package:flutter/material.dart';

/// Card shadow — makes cards appear elevated above the screen
/// (ported from constants/shadows.ts).
const List<BoxShadow> cardShadow = [
  BoxShadow(color: Color(0x8C000000), offset: Offset(0, 6), blurRadius: 24),
];

/// Lighter shadow for smaller/inner cards.
const List<BoxShadow> cardShadowSm = [
  BoxShadow(color: Color(0x66000000), offset: Offset(0, 3), blurRadius: 12),
];
