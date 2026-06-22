import 'dart:async';

import 'package:flutter/material.dart';

import 'i18n/strings.dart';
import 'screens/splash_screen.dart';
import 'services/auth_service.dart';
import 'services/language_service.dart';
import 'theme/app_colors.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Fire-and-forget: the SplashScreen waits until both services report ready
  // before routing on to the AuthGate.
  unawaited(AuthService.instance.init());
  unawaited(LanguageService.instance.init());
  runApp(const DillAdalaApp());
}

class DillAdalaApp extends StatelessWidget {
  const DillAdalaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LanguageService.instance,
      builder: (context, _) {
        final lang = LanguageService.instance;
        return MaterialApp(
          title: t('common.firmShort'),
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            brightness: Brightness.dark,
            fontFamily: lang.fontFamily,
            scaffoldBackgroundColor: AppColors.background,
            colorScheme: const ColorScheme.dark(
              primary: AppColors.gold,
              secondary: AppColors.gold,
              surface: AppColors.card,
              error: AppColors.destructive,
            ),
            useMaterial3: true,
          ),
          builder: (context, child) => Directionality(
            textDirection: lang.dir,
            child: child ?? const SizedBox.shrink(),
          ),
          home: const SplashScreen(),
        );
      },
    );
  }
}
