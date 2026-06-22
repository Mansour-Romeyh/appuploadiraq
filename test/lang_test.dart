import 'package:flutter_test/flutter_test.dart';
import 'package:dill_adala/i18n/lang.dart';

void main() {
  test('code round-trips through fromCode', () {
    for (final l in Lang.values) {
      expect(Lang.fromCode(l.code), l);
    }
  });

  test('fromCode falls back to ar for unknown input', () {
    expect(Lang.fromCode('xx'), Lang.ar);
    expect(Lang.fromCode(null), Lang.ar);
  });

  test('ar and ku are RTL, en is LTR', () {
    expect(Lang.ar.isRtl, isTrue);
    expect(Lang.ku.isRtl, isTrue);
    expect(Lang.en.isRtl, isFalse);
  });

  test('langOrder is ar, en, ku', () {
    expect(langOrder, [Lang.ar, Lang.en, Lang.ku]);
  });

  test('langMeta has native names', () {
    expect(langMeta[Lang.ar]!.native, 'العربية');
    expect(langMeta[Lang.en]!.native, 'English');
    expect(langMeta[Lang.ku]!.native, 'کوردی');
  });
}
