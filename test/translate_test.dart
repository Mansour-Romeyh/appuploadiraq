import 'package:flutter_test/flutter_test.dart';
import 'package:dill_adala/i18n/lang.dart';
import 'package:dill_adala/i18n/strings.dart';

void main() {
  test('resolves a namespaced key in the active language', () {
    expect(translate('common.tab.home', Lang.ar), 'الرئيسية');
    expect(translate('common.tab.home', Lang.en), 'Home');
    expect(translate('common.tab.home', Lang.ku), 'سەرەکی');
  });

  test('common.* keys are also reachable unprefixed', () {
    expect(translate('back', Lang.en), 'Back');
    expect(translate('common.back', Lang.en), 'Back');
  });

  test('unknown key returns the key itself', () {
    expect(translate('nope.missing', Lang.en), 'nope.missing');
  });

  test('interpolates {vars}', () {
    expect(
      interpolate('Hello {name} and {name}', {'name': 'Sam'}),
      'Hello Sam and Sam',
    );
  });
}
