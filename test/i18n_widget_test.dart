import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dill_adala/i18n/lang.dart';
import 'package:dill_adala/services/auth_service.dart';
import 'package:dill_adala/services/language_service.dart';
import 'package:dill_adala/main.dart';

/// Flutter 3.41 removed ThemeData.fontFamily as a public getter.
/// The fontFamily constructor param is applied to every TextStyle via
/// textTheme.apply(), so we read it back from bodyMedium.fontFamily.
String? themeFont(MaterialApp app) =>
    app.theme?.textTheme.bodyMedium?.fontFamily;

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LanguageService.instance.resetForTest();
  });

  testWidgets('theme font + direction follow the active language', (
    tester,
  ) async {
    await LanguageService.instance.init();
    await AuthService.instance.init();
    await tester.pumpWidget(const DillAdalaApp());
    await tester.pump(const Duration(milliseconds: 50));

    MaterialApp app() => tester.widget<MaterialApp>(find.byType(MaterialApp));

    // Default Arabic → Cairo + RTL.
    expect(themeFont(app()), 'Cairo');
    expect(LanguageService.instance.dir, TextDirection.rtl);

    // English → Cairo + LTR.
    await LanguageService.instance.setLang(Lang.en);
    await tester.pump(const Duration(milliseconds: 50));
    expect(themeFont(app()), 'Cairo');
    expect(LanguageService.instance.dir, TextDirection.ltr);

    // Kurdish → NRT font on the theme.
    await LanguageService.instance.setLang(Lang.ku);
    await tester.pump(const Duration(milliseconds: 50));
    expect(themeFont(app()), 'NRT');
  });

  testWidgets('builder applies the language direction below MaterialApp', (
    tester,
  ) async {
    await LanguageService.instance.init();
    await AuthService.instance.init();
    await tester.pumpWidget(const DillAdalaApp());
    await tester.pump(const Duration(milliseconds: 50));

    // A Scaffold renders (splash or login); read the Directionality applied
    // by the MaterialApp.builder above it.
    final scaffold = find.byType(Scaffold);
    expect(scaffold, findsWidgets);
    expect(
      Directionality.of(tester.element(scaffold.first)),
      TextDirection.rtl,
    );

    await LanguageService.instance.setLang(Lang.en);
    await tester.pump(const Duration(milliseconds: 50));
    expect(
      Directionality.of(tester.element(find.byType(Scaffold).first)),
      TextDirection.ltr,
    );
  });

  testWidgets('on-screen text follows the active language', (tester) async {
    await LanguageService.instance.init(); // default ar
    await AuthService.instance.init(); // logged out -> LoginScreen
    await tester.pumpWidget(const DillAdalaApp());
    await tester.pump(const Duration(milliseconds: 50));

    // Arabic welcome is shown by default.
    expect(find.text('أهلاً بك'), findsWidgets);

    // Switch to English: the welcome header re-renders in English.
    await LanguageService.instance.setLang(Lang.en);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Welcome'), findsWidgets);
    expect(find.text('أهلاً بك'), findsNothing);
  });
}
