import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dill_adala/i18n/strings.dart';
import 'package:dill_adala/screens/profile_screen.dart';
import 'package:dill_adala/services/auth_service.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('guest sees Privacy Policy but not Delete account',
      (tester) async {
    await AuthService.instance.logout();
    await tester.pumpWidget(const MaterialApp(home: ProfileScreen()));
    await tester.pumpAndSettle();

    expect(find.text(t('profile.privacyPolicy')), findsOneWidget);
    expect(find.text(t('profile.deleteAccount')), findsNothing);
  });

  testWidgets('authenticated user sees both Privacy Policy and Delete account',
      (tester) async {
    await AuthService.instance.login(const AuthUser(
      name: 'Test User',
      phone: '+9647700000000',
      method: AuthMethod.phone,
      apiKey: 'k',
      apiSecret: 's',
    ));
    await tester.pumpWidget(const MaterialApp(home: ProfileScreen()));
    await tester.pumpAndSettle();

    expect(find.text(t('profile.privacyPolicy')), findsOneWidget);
    expect(find.text(t('profile.deleteAccount')), findsOneWidget);

    await AuthService.instance.logout();
  });
}
