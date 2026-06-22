import 'package:flutter_test/flutter_test.dart';
import 'package:dill_adala/i18n/lang.dart';
import 'package:dill_adala/i18n/strings.dart';

void main() {
  test('all sections are registered and resolve', () {
    const probes = <String>[
      'auth.welcome',
      'home.heroSlogan',
      'team.screenTitle',
      'cases.screenTitle',
      'laws.screenTitle',
      'ai.headerTitle',
      'contact.headerTitle',
      'services.screenTitle',
      'news.screenTitle',
      'components.error.unexpected',
      'profile.title',
    ];
    for (final key in probes) {
      for (final lang in Lang.values) {
        final v = translate(key, lang);
        expect(v, isNotEmpty, reason: '$key/$lang empty');
        expect(v, isNot(key), reason: '$key/$lang missing (returned the key)');
      }
    }
  });

  test('every entry defines all three languages', () {
    dict.forEach((key, entry) {
      for (final lang in Lang.values) {
        expect(entry[lang], isNotNull, reason: 'missing $lang for "$key"');
      }
    });
  });
}
