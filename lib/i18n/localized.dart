import 'lang.dart';

/// A piece of localized *content* (data), e.g. a service title from the API.
/// Arabic is authoritative and always present; other languages fall back to it.
class Localized {
  final String ar;
  final String? en;
  final String? ku;

  const Localized({required this.ar, this.en, this.ku});

  String resolve(Lang lang) => switch (lang) {
        Lang.ar => ar,
        Lang.en => (en == null || en!.isEmpty) ? ar : en!,
        Lang.ku => (ku == null || ku!.isEmpty) ? ar : ku!,
      };

  /// Accepts either a `{ar,en,ku}` map (as the backend returns) or a bare
  /// string (treated as Arabic-only). Null/other becomes empty Arabic.
  factory Localized.fromJson(Object? json) {
    if (json is String) return Localized(ar: json);
    if (json is Map) {
      return Localized(
        ar: (json['ar'] as String?) ?? '',
        en: json['en'] as String?,
        ku: json['ku'] as String?,
      );
    }
    return const Localized(ar: '');
  }
}
