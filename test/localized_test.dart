import 'package:flutter_test/flutter_test.dart';
import 'package:dill_adala/i18n/lang.dart';
import 'package:dill_adala/i18n/localized.dart';

void main() {
  const full = Localized(ar: 'مرحبا', en: 'Hello', ku: 'سڵاو');

  test('resolve returns the requested language', () {
    expect(full.resolve(Lang.ar), 'مرحبا');
    expect(full.resolve(Lang.en), 'Hello');
    expect(full.resolve(Lang.ku), 'سڵاو');
  });

  test('resolve falls back to Arabic when a language is missing', () {
    const arOnly = Localized(ar: 'فقط');
    expect(arOnly.resolve(Lang.en), 'فقط');
    expect(arOnly.resolve(Lang.ku), 'فقط');
  });

  test('fromJson parses an {ar,en,ku} map', () {
    final l = Localized.fromJson({'ar': 'أ', 'en': 'a', 'ku': 'ا'});
    expect(l.resolve(Lang.en), 'a');
  });

  test('fromJson treats a bare string as Arabic-only', () {
    final l = Localized.fromJson('نص');
    expect(l.resolve(Lang.en), 'نص');
  });

  test('fromJson tolerates null/empty into empty Arabic', () {
    expect(Localized.fromJson(null).resolve(Lang.ar), '');
  });
}
