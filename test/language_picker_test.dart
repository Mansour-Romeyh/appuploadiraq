import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dill_adala/i18n/lang.dart';
import 'package:dill_adala/services/language_service.dart';
import 'package:dill_adala/widgets/language_picker.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LanguageService.instance.resetForTest();
  });

  testWidgets('selecting a language updates the service', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showLanguagePicker(context),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('العربية'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('کوردی'), findsOneWidget);

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(LanguageService.instance.lang, Lang.en);
  });
}
