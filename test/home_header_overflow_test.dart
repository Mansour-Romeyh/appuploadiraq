import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dill_adala/i18n/lang.dart';
import 'package:dill_adala/services/auth_service.dart';
import 'package:dill_adala/services/language_service.dart';
import 'package:dill_adala/main.dart';

/// Reproduction for the home-header overflow: the longer English and Kurdish
/// firm names ("Shadow of Justice" / "سێبەری دادپەروەری") plus the avatar and the
/// three right-side controls overflow a narrow phone width because the header
/// row was not flexible. Renders the home tab narrow in each language and
/// asserts no RenderFlex overflow is thrown.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LanguageService.instance.resetForTest();
    AuthService.instance.logout();
  });

  Future<void> pumpHomeNarrow(WidgetTester tester, Lang lang) async {
    tester.view.physicalSize = const Size(360, 720);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await LanguageService.instance.init();
    await AuthService.instance.init();
    await AuthService.instance.continueAsGuest();
    await LanguageService.instance.setLang(lang);
    await tester.pumpWidget(const DillAdalaApp());
    await tester.pump(const Duration(milliseconds: 50));
  }

  for (final lang in [Lang.en, Lang.ku, Lang.ar]) {
    testWidgets('home header does not overflow on a narrow screen ($lang)', (
      tester,
    ) async {
      await pumpHomeNarrow(tester, lang);
      expect(tester.takeException(), isNull);
    });
  }
}
