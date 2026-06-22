import 'lang.dart';
import 'sections/common.dart';
import 'sections/auth.dart';
import 'sections/home.dart';
import 'sections/team.dart';
import 'sections/cases.dart';
import 'sections/laws.dart';
import 'sections/ai.dart';
import 'sections/contact.dart';
import 'sections/services.dart';
import 'sections/news.dart';
import 'sections/components.dart';
import 'sections/profile.dart';
import 'sections/office.dart';
import 'sections/notifications.dart';
import '../services/language_service.dart';

/// Every ported section, registered by its namespace. Adding a section here is
/// the only wiring step needed for its keys to resolve.
const Map<String, Map<String, Map<Lang, String>>> _sections = {
  'common': common,
  'auth': auth,
  'home': home,
  'team': team,
  'cases': cases,
  'laws': laws,
  'ai': ai,
  'contact': contact,
  'services': services,
  'news': news,
  'components': components,
  'profile': profile,
  'office': office,
  'notifications': notifications,
};

/// Flattened "section.key" → per-language entry, built once at first library load.
/// `common.*` keys are also registered unprefixed (matches the RN behavior).
final Map<String, Map<Lang, String>> dict = _buildDict();

Map<String, Map<Lang, String>> _buildDict() {
  final out = <String, Map<Lang, String>>{};
  _sections.forEach((ns, section) {
    section.forEach((key, entry) {
      out['$ns.$key'] = entry;
      if (ns == 'common') out[key] = entry;
    });
  });
  return out;
}

/// Replace every `{name}` token with its stringified value.
/// Values are substituted as-is; any `{...}` inside a value is NOT re-expanded.
String interpolate(String input, Map<String, Object> vars) {
  var out = input;
  vars.forEach((k, v) {
    out = out.replaceAll('{$k}', '$v');
  });
  return out;
}

/// Pure translator: entry[lang] ?? entry[ar] ?? key, then interpolate vars.
String translate(String key, Lang lang, {Map<String, Object>? vars}) {
  final entry = dict[key];
  var out = entry == null ? key : (entry[lang] ?? entry[Lang.ar] ?? key);
  if (vars != null) out = interpolate(out, vars);
  return out;
}

String t(String key, {Map<String, Object>? vars}) =>
    translate(key, LanguageService.instance.lang, vars: vars);
