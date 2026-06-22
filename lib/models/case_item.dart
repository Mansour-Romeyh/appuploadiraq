import 'package:flutter/material.dart';

/// Stable Arabic status keys used by the backend (`RemoteCase.status`) and as
/// the color/i18n lookup key. Mirrors `CaseStatus` in law-firm-app/data/cases.ts.
/// Values are Arabic strings (historical) — do NOT change them.
enum CaseStatus {
  ongoing('جارية', Color(0xFF1565C0)),
  pending('معلّقة', Color(0xFFF57F17)),
  closed('مغلقة', Color(0xFF37474F)),
  won('فائزة', Color(0xFF2E7D32)),
  lost('خاسرة', Color(0xFFC0392B));

  const CaseStatus(this.key, this.color);

  /// Stable Arabic key, matching the backend status value and the
  /// `cases.status.<key>` i18n keys.
  final String key;
  final Color color;

  /// Backwards-compatible alias — the key doubles as the raw display label.
  String get label => key;

  static CaseStatus fromLabel(String label) =>
      values.firstWhere((s) => s.key == label, orElse: () => ongoing);

  /// Look up a status by its stable key, or null when the key is unknown
  /// (e.g. a backend status the client doesn't model).
  static CaseStatus? byKey(String key) {
    for (final s in values) {
      if (s.key == key) return s;
    }
    return null;
  }
}

/// Status keys in canonical display order (mirrors STATUS_OPTIONS).
const List<String> kStatusOptions = [
  'جارية',
  'معلّقة',
  'مغلقة',
  'فائزة',
  'خاسرة',
];
