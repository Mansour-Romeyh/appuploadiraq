import '../i18n/localized.dart';

/// A Legal Team Member, as returned by `law_firm.api.mobile.get_team`.
/// Localized text fields carry `{ar,en,ku}`; resolve them with `tr(...)`.
class Lawyer {
  final String id;
  final Localized name;
  final Localized title;
  final Localized specialty;
  final int experience;
  final int cases;
  final Localized bio;
  final Localized education;
  final String phone;
  final String email;
  final bool available;
  final Localized nextAvailable;

  /// Root-relative (or absolute) media path from the backend; "" when unset.
  final String photoUrl;

  const Lawyer({
    required this.id,
    required this.name,
    required this.title,
    required this.specialty,
    required this.experience,
    required this.cases,
    required this.bio,
    required this.education,
    required this.phone,
    required this.email,
    required this.available,
    required this.nextAvailable,
    required this.photoUrl,
  });

  factory Lawyer.fromJson(Map<String, dynamic> j) => Lawyer(
    id: j['id']?.toString() ?? '',
    name: Localized.fromJson(j['name']),
    title: Localized.fromJson(j['title']),
    specialty: Localized.fromJson(j['specialty']),
    experience: (j['experience'] as num?)?.toInt() ?? 0,
    cases: (j['cases'] as num?)?.toInt() ?? 0,
    bio: Localized.fromJson(j['bio']),
    education: Localized.fromJson(j['education']),
    phone: j['phone'] as String? ?? '',
    email: j['email'] as String? ?? '',
    available: j['available'] == true,
    nextAvailable: Localized.fromJson(j['nextAvailable']),
    photoUrl: j['photoUrl'] as String? ?? '',
  );
}
