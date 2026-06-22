import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dill_adala/i18n/lang.dart';
import 'package:dill_adala/services/auth_service.dart';
import 'package:dill_adala/services/language_service.dart';
import 'package:dill_adala/main.dart';

/// Reproduction for the "language switch is stuck" bug: inside the authenticated
/// tab shell, none of the tab screens subscribe to LanguageService, so switching
/// languages must re-translate them via a rebuild from above. This guards that
/// the home tab's content actually re-renders in the new language.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LanguageService.instance.resetForTest();
    AuthService.instance.logout();
  });

  testWidgets('home tab text re-translates when language changes', (
    tester,
  ) async {
    await LanguageService.instance.init(); // default ar
    await AuthService.instance.init();
    await AuthService.instance.continueAsGuest(); // enter TabsShell
    await tester.pumpWidget(const DillAdalaApp());
    await tester.pump(const Duration(milliseconds: 50));

    // Arabic firm name is shown on the home header by default.
    expect(find.text('ظل العدالة'), findsWidgets);

    // Switch ar -> en: the home header must re-render in English.
    await LanguageService.instance.setLang(Lang.en);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Shadow of Justice'), findsWidgets);
    expect(find.text('ظل العدالة'), findsNothing);

    // Switch en -> ku: and back into a third language.
    await LanguageService.instance.setLang(Lang.ku);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('سێبەری دادپەروەری'), findsWidgets);
    expect(find.text('Shadow of Justice'), findsNothing);

    // Switch ku -> ar: the original "stuck" direction in the bug report.
    await LanguageService.instance.setLang(Lang.ar);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('ظل العدالة'), findsWidgets);
    expect(find.text('سێبەری دادپەروەری'), findsNothing);
  });

  testWidgets('tab bar label re-translates when language changes', (
    tester,
  ) async {
    await LanguageService.instance.init();
    await AuthService.instance.init();
    await AuthService.instance.continueAsGuest();
    await tester.pumpWidget(const DillAdalaApp());
    await tester.pump(const Duration(milliseconds: 50));

    // Home tab is focused at index 0; its label shows in the floating bar.
    expect(find.text('الرئيسية'), findsWidgets);

    await LanguageService.instance.setLang(Lang.en);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Home'), findsWidgets);
    expect(find.text('الرئيسية'), findsNothing);
  });
}
