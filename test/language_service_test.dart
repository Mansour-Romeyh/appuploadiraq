import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dill_adala/i18n/lang.dart';
import 'package:dill_adala/services/language_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LanguageService.instance.resetForTest();
  });

  test('defaults to Arabic before init', () {
    expect(LanguageService.instance.lang, Lang.ar);
    expect(LanguageService.instance.isReady, isFalse);
  });

  test('init loads a persisted language', () async {
    SharedPreferences.setMockInitialValues({'law_firm_lang_v1': 'en'});
    await LanguageService.instance.init();
    expect(LanguageService.instance.lang, Lang.en);
    expect(LanguageService.instance.isReady, isTrue);
  });

  test('init defaults to ar when nothing is stored', () async {
    await LanguageService.instance.init();
    expect(LanguageService.instance.lang, Lang.ar);
  });

  test('setLang persists and notifies', () async {
    var notified = 0;
    void listener() => notified++;
    LanguageService.instance.addListener(listener);
    addTearDown(() => LanguageService.instance.removeListener(listener));
    await LanguageService.instance.setLang(Lang.ku);
    expect(LanguageService.instance.lang, Lang.ku);
    expect(notified, greaterThan(0));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('law_firm_lang_v1'), 'ku');
  });

  test('direction and font follow the language', () async {
    await LanguageService.instance.setLang(Lang.ku);
    expect(LanguageService.instance.isRTL, isTrue);
    expect(LanguageService.instance.fontFamily, 'NRT');
    await LanguageService.instance.setLang(Lang.en);
    expect(LanguageService.instance.isRTL, isFalse);
    expect(LanguageService.instance.fontFamily, 'Cairo');
  });

  test('t delegates to the active language', () async {
    await LanguageService.instance.setLang(Lang.en);
    expect(LanguageService.instance.t('common.tab.home'), 'Home');
  });
}
