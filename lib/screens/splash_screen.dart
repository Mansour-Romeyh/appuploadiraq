import 'dart:async';

import 'package:flutter/material.dart';

import '../i18n/strings.dart';
import '../services/auth_service.dart';
import '../services/language_service.dart';
import '../theme/app_colors.dart';
import 'auth_gate.dart';

/// Elegant launch screen. The native splash (flutter_native_splash) covers the
/// engine cold-start with the same black background + logo, then this screen
/// fades and scales the brand in while [AuthService]/[LanguageService] finish
/// loading, and routes on to the app. A minimum dwell keeps the animation from
/// being cut short on fast devices.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _minDwell = Duration(milliseconds: 2000);

  late final AnimationController _controller;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _textFade;
  late final Animation<double> _dividerWidth;

  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Logo: fade + gentle scale-up over the first ~60% of the timeline.
    _logoFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );
    _logoScale = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );
    // Gold divider draws outward, then the name/caption fade in last.
    _dividerWidth = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 0.75, curve: Curves.easeOutCubic),
    );
    _textFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.55, 1.0, curve: Curves.easeOut),
    );

    _controller.forward();
    _scheduleNavigation();
  }

  /// Waits for both the minimum dwell and for the services to report ready,
  /// then routes to the appropriate first screen.
  Future<void> _scheduleNavigation() async {
    final auth = AuthService.instance;
    final lang = LanguageService.instance;

    await Future.wait([
      Future<void>.delayed(_minDwell),
      _untilReady(auth, () => auth.isReady),
      _untilReady(lang, () => lang.isReady),
    ]);
    if (!mounted || _navigated) return;
    _navigated = true;

    // Route to the reactive AuthGate (not straight to a screen) so later
    // login/logout still swap the home content automatically.
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, _, _) => const AuthGate(),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  /// Completes once [ready] is true, listening to [listenable] until then.
  Future<void> _untilReady(Listenable listenable, bool Function() ready) {
    if (ready()) return Future<void>.value();
    final completer = Completer<void>();
    void listener() {
      if (ready() && !completer.isCompleted) {
        listenable.removeListener(listener);
        completer.complete();
      }
    }

    listenable.addListener(listener);
    return completer.future;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo in a gold-ringed circle, matching the login screen.
              Opacity(
                opacity: _logoFade.value,
                child: Transform.scale(
                  scale: _logoScale.value,
                  child: Container(
                    width: 132,
                    height: 132,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.gold.withAlpha(0x55),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.gold.withAlpha(0x33),
                          blurRadius: 36,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      'assets/images/law-logo.jpg',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 26),

              // Gold divider with a centered diamond, drawn outward.
              Opacity(
                opacity: _dividerWidth.value,
                child: _GoldDivider(extent: _dividerWidth.value),
              ),
              const SizedBox(height: 18),

              // Firm name (stays Arabic in every language, like the login screen).
              Opacity(
                opacity: _textFade.value,
                child: const Text(
                  'شركة ظل العدالة',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Opacity(
                opacity: _textFade.value,
                child: Text(
                  t('auth.subtitle'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0x80FFFFFF),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Subtle gold loader.
              Opacity(
                opacity: _textFade.value,
                child: const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.gold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A thin gold rule with a diamond at its centre; [extent] (0..1) scales the
/// rule width so it appears to draw outward during the splash animation.
class _GoldDivider extends StatelessWidget {
  final double extent;

  const _GoldDivider({required this.extent});

  @override
  Widget build(BuildContext context) {
    final lineWidth = 56.0 * extent;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: lineWidth,
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.gold.withAlpha(0), AppColors.gold],
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Icon(Icons.diamond_outlined, size: 12, color: AppColors.gold),
        ),
        Container(
          width: lineWidth,
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.gold, AppColors.gold.withAlpha(0)],
            ),
          ),
        ),
      ],
    );
  }
}
