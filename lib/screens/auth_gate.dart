import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/language_service.dart';
import '../theme/app_colors.dart';
import 'login_screen.dart';
import 'tabs_shell.dart';

/// Shows login or the main tab shell depending on auth state, after both the
/// language and auth singletons have finished loading. Reacts to later auth
/// changes (login / logout) by swapping the home content automatically.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        AuthService.instance,
        LanguageService.instance,
      ]),
      builder: (context, _) {
        final auth = AuthService.instance;
        final lang = LanguageService.instance;
        if (!auth.isReady || !lang.isReady) {
          return const Scaffold(
            backgroundColor: AppColors.navy,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.gold),
            ),
          );
        }
        return auth.hasAuth ? const TabsShell() : const LoginScreen();
      },
    );
  }
}
