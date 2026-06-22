import 'package:flutter/material.dart';

/// The backend (`Legal Service.icon`) stores a Feather icon *name* string, the
/// same value the reference RN app feeds to `<Feather name=… />`. Flutter has no
/// Feather font bundled, so we map the names the content actually uses to the
/// Material icons this app already used for those services — keeping the build
/// free of an icon-font dependency. Unknown names fall back to a neutral gavel.
const Map<String, IconData> _featherToMaterial = {
  'shield': Icons.shield_outlined,
  'heart': Icons.favorite_border,
  'briefcase': Icons.work_outline,
  'home': Icons.home_outlined,
  'users': Icons.people_outline,
  'flag': Icons.flag_outlined,
  'award': Icons.workspace_premium_outlined,
  'git-merge': Icons.call_merge,
};

IconData featherIcon(String name) => _featherToMaterial[name] ?? Icons.gavel;

/// Parse a `#RRGGBB` (or `#AARRGGBB`) hex string from the API into a [Color].
/// Falls back to a neutral slate when the value is empty or malformed.
Color parseHexColor(String hex) {
  var value = hex.trim();
  if (value.startsWith('#')) value = value.substring(1);
  if (value.length == 6) value = 'FF$value';
  final parsed = int.tryParse(value, radix: 16);
  return parsed == null ? const Color(0xFF37474F) : Color(parsed);
}
