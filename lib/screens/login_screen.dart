import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/countries.dart';
import '../i18n/strings.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/language_service.dart';
import '../theme/app_colors.dart';
import '../widgets/country_code_picker.dart';
import 'otp_screen.dart';

/// Login screen: Apple (iOS-only mock) + phone → OTP flow + guest access
/// (ported from app/(auth)/login.tsx).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  bool _showPhoneField = false;
  Country _country = defaultCountry;
  bool _appleLoading = false;
  bool _phoneLoading = false;
  String _phoneError = '';

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String get _rawDigits => _phoneController.text.replaceAll(RegExp(r'\D'), '');
  bool get _isIraq => _country.dial == '+964';

  /// Iraqi rule: 10 digits starting with 7, or 11 digits starting with 0.
  bool get _phoneValid {
    final d = _rawDigits;
    if (_isIraq) {
      return (d.length == 10 && d.startsWith('7')) ||
          (d.length == 11 && d.startsWith('0'));
    }
    return d.replaceAll(RegExp(r'^0+'), '').length >= 7;
  }

  /// Local part sent to the backend — drop any leading 0 (11-digit → 10-digit).
  String get _localDigits => _rawDigits.replaceAll(RegExp(r'^0+'), '');

  /// Inline hint once a near-complete but invalid Iraqi number is typed.
  String get _phoneRuleError =>
      (_isIraq && _rawDigits.length >= 10 && !_phoneValid)
      ? t('auth.phoneInvalidIraq')
      : '';

  Future<void> _mockAppleLogin() async {
    if (_appleLoading) return;
    HapticFeedback.lightImpact();
    setState(() => _appleLoading = true);
    await Future<void>.delayed(const Duration(milliseconds: 1600));
    if (!mounted) return;
    await AuthService.instance.login(
      const AuthUser(
        name: 'محمد العلي',
        email: 'ali@icloud.com',
        method: AuthMethod.apple,
      ),
    );
  }

  Future<void> _handlePhoneContinue() async {
    if (!_phoneValid || _phoneLoading) return;
    final fullPhone = '${_country.dial}$_localDigits';
    HapticFeedback.lightImpact();
    setState(() {
      _phoneError = '';
      _phoneLoading = true;
    });
    try {
      final result = await ApiService.instance.sendOtp(fullPhone);
      if (!mounted) return;
      // Backend reports registered === false when no enabled User has this
      // number. (Older backends omit the field — null means proceed.)
      if (result.registered == false) {
        setState(() => _phoneError = t('auth.phoneNotRegistered'));
        return;
      }
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => OtpScreen(phone: fullPhone)));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(
        () => _phoneError = e.code == ApiErrorCode.throttled
            ? t('auth.otpThrottled')
            : t('auth.otpSendFailed'),
      );
    } finally {
      if (mounted) setState(() => _phoneLoading = false);
    }
  }

  Future<void> _handleGuest() async {
    HapticFeedback.lightImpact();
    await AuthService.instance.continueAsGuest();
  }

  Future<void> _openCountryPicker() async {
    HapticFeedback.lightImpact();
    final picked = await showCountryCodePicker(context, selected: _country);
    if (picked != null && mounted) setState(() => _country = picked);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LanguageService.instance,
      builder: (context, _) => _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final insets = MediaQuery.of(context).padding;

    return Scaffold(
      backgroundColor: AppColors.navy,
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: insets.top + 24,
          bottom: insets.bottom + 24,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight:
                MediaQuery.of(context).size.height -
                insets.top -
                insets.bottom -
                48,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  // Logo + headline
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.gold.withAlpha(0x44),
                        width: 2,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      'assets/images/law-logo.jpg',
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Brand/logo title stays in Arabic in every language.
                  const Text(
                    'شركة ظل العدالة',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.gold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    t('auth.welcome'),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t('auth.subtitle'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0x80FFFFFF),
                      height: 22 / 14,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Auth buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        // Apple social login — iOS only (matches reference).
                        if (Platform.isIOS) ...[
                          _SocialButton(
                            onPressed: _appleLoading ? null : _mockAppleLogin,
                            child: _appleLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF333333),
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.apple,
                                        size: 22,
                                        color: Colors.black,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        t('auth.continueWithApple'),
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1A1A1A),
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Expanded(
                                child: Divider(color: Color(0x26FFFFFF)),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Text(
                                  t('or'),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0x66FFFFFF),
                                  ),
                                ),
                              ),
                              const Expanded(
                                child: Divider(color: Color(0x26FFFFFF)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],

                        if (_showPhoneField)
                          _buildPhoneSection()
                        else
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.gold,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: () =>
                                  setState(() => _showPhoneField = true),
                              icon: const Icon(
                                Icons.phone_outlined,
                                size: 19,
                                color: AppColors.navy,
                              ),
                              label: Text(
                                t('auth.continueWithPhone'),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.navy,
                                ),
                              ),
                            ),
                          ),

                        if (_phoneError.isNotEmpty ||
                            _phoneRuleError.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                              _phoneError.isNotEmpty
                                  ? _phoneError
                                  : _phoneRuleError,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFFEF4444),
                                fontSize: 13,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),

              // Guest access — pinned to bottom
              Padding(
                padding: const EdgeInsets.only(top: 32),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Divider(color: Color(0x1AFFFFFF)),
                        ),
                        TextButton.icon(
                          onPressed: _handleGuest,
                          icon: Text(
                            t('auth.browseAsGuest'),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0x73FFFFFF),
                            ),
                          ),
                          label: const Icon(
                            Icons.visibility_outlined,
                            size: 14,
                            color: Color(0x59FFFFFF),
                          ),
                        ),
                        const Expanded(
                          child: Divider(color: Color(0x1AFFFFFF)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      t('auth.guestHint'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0x40FFFFFF),
                        height: 18 / 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneSection() {
    return Column(
      children: [
        // Country pill + number field on one row.
        Row(
          children: [
            GestureDetector(
              onTap: _openCountryPicker,
              child: Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0x14FFFFFF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0x26FFFFFF)),
                ),
                child: Row(
                  children: [
                    Text(_country.flag, style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 5),
                    Text(
                      _country.dial,
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Icon(
                      Icons.keyboard_arrow_down,
                      size: 18,
                      color: Color(0x99FFFFFF),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _phoneController,
                autofocus: true,
                keyboardType: TextInputType.phone,
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.left,
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _handlePhoneContinue(),
                style: const TextStyle(fontSize: 16, color: Colors.white),
                decoration: InputDecoration(
                  hintText: t('auth.phonePlaceholder'),
                  hintStyle: const TextStyle(color: Color(0x59FFFFFF)),
                  hintTextDirection: TextDirection.ltr,
                  filled: true,
                  fillColor: const Color(0x14FFFFFF),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0x26FFFFFF)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.gold),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // WhatsApp requirement note.
        Row(
          children: [
            const Icon(
              Icons.chat_bubble_outline,
              size: 14,
              color: Color(0xFF25D366),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                t('auth.whatsappRequired'),
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0x8CFFFFFF),
                  height: 18 / 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Submit button — full width below the field.
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _phoneValid
                  ? AppColors.gold
                  : const Color(0x1FFFFFFF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: _phoneValid ? _handlePhoneContinue : null,
            child: _phoneLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.navy,
                    ),
                  )
                : Icon(
                    Icons.arrow_forward,
                    size: 22,
                    color: _phoneValid
                        ? AppColors.navy
                        : const Color(0x4DFFFFFF),
                  ),
          ),
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;

  const _SocialButton({required this.onPressed, required this.child});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: onPressed,
        child: child,
      ),
    );
  }
}
