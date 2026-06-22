import '../i18n/localized.dart';

/// A Legal Service, as returned by `law_firm.api.mobile.get_services`.
///
/// `icon` is a Feather icon-name string and `color` a `#RRGGBB` string (resolve
/// them with `featherIcon(...)` / `parseHexColor(...)`); the text fields carry
/// `{ar,en,ku}` and resolve with `tr(...)`.
class LegalService {
  final String id;
  final Localized title;
  final Localized description;
  final Localized details;
  final List<Localized> bullets;
  final String icon;
  final String color;

  const LegalService({
    required this.id,
    required this.title,
    required this.description,
    required this.details,
    required this.bullets,
    required this.icon,
    required this.color,
  });

  factory LegalService.fromJson(Map<String, dynamic> j) => LegalService(
    id: j['id']?.toString() ?? '',
    title: Localized.fromJson(j['title']),
    description: Localized.fromJson(j['description']),
    details: Localized.fromJson(j['details']),
    bullets: ((j['bullets'] as List?) ?? const [])
        .map(Localized.fromJson)
        .toList(),
    icon: j['icon'] as String? ?? '',
    color: j['color'] as String? ?? '',
  );
}
