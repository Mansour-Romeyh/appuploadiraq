import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../i18n/strings.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';

const int _otpLength = 6;
const int _resendSeconds = 60;

/// OTP verification screen (ported from app/(auth)/otp.tsx).
/// Verifies the code against the backend (verify_otp) and stores the issued
/// api_key/api_secret on the logged-in user.
class OtpScreen extends StatefulWidget {
  final String phone;

  const OtpScreen({super.key, required this.phone});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _controllers = List.generate(
    _otpLength,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    _otpLength,
    (_) => FocusNode(),
  );

  bool _loading = false;
  String _error = '';
  int _resendTimer = _resendSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimer <= 0) {
        timer.cancel();
        return;
      }
      setState(() => _resendTimer--);
    });
  }

  int get _filledCount => _controllers.where((c) => c.text.isNotEmpty).length;

  Future<void> _verify() async {
    final code = _controllers.map((c) => c.text).join();
    if (code.length != _otpLength) return;
    setState(() {
      _loading = true;
      _error = '';
    });
    HapticFeedback.mediumImpact();
    try {
      final result = await ApiService.instance.verifyOtp(widget.phone, code);
      if (!mounted) return;
      if (result.ok) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        await AuthService.instance.login(
          AuthUser(
            name: (result.fullName?.isNotEmpty ?? false)
                ? result.fullName!
                : (result.name ?? ''),
            phone: result.mobileNo ?? widget.phone,
            email: result.email,
            method: AuthMethod.phone,
            isLawyer: result.isLawyer,
            apiKey: result.apiKey,
            apiSecret: result.apiSecret,
          ),
        );
      } else {
        for (final c in _controllers) {
          c.clear();
        }
        setState(() {
          _error = result.error == 'expired'
              ? t('auth.otpExpired')
              : result.error == 'too_many_attempts'
              ? t('auth.otpTooMany')
              : t('auth.otpInvalid');
        });
        _focusNodes[0].requestFocus();
      }
    } catch (_) {
      if (mounted) setState(() => _error = t('auth.otpSendFailed'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onChanged(int index, String value) {
    if (value.isNotEmpty && index < _otpLength - 1) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    setState(() => _error = '');
    if (_controllers.every((c) => c.text.isNotEmpty)) {
      _focusNodes[_otpLength - 1].unfocus();
      _verify();
    }
  }

  Future<void> _handleResend() async {
    if (_resendTimer > 0) return;
    for (final c in _controllers) {
      c.clear();
    }
    setState(() {
      _resendTimer = _resendSeconds;
      _error = '';
    });
    _startTimer();
    _focusNodes[0].requestFocus();
    HapticFeedback.lightImpact();
    try {
      await ApiService.instance.sendOtp(widget.phone);
    } on ApiException catch (e) {
      if (mounted) {
        setState(
          () => _error = e.code == ApiErrorCode.throttled
              ? t('auth.otpThrottled')
              : t('auth.otpSendFailed'),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.of(context).padding;
    final canVerify = _filledCount == _otpLength && !_loading;

    return Scaffold(
      backgroundColor: AppColors.navy,
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.only(
              top: insets.top + 12,
              left: 20,
              right: 20,
              bottom: 8,
            ),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0x1FFFFFFF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: AppColors.gold.withAlpha(0x18),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.sms_outlined,
                            size: 32,
                            color: AppColors.gold,
                          ),
                        ),
                        const SizedBox(height: 22),
                        Text(
                          t('auth.otpTitle'),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text.rich(
                          TextSpan(
                            text: "${t('auth.otpSubtitle')}\n",
                            style: const TextStyle(
                              fontSize: 15,
                              color: Color(0x8CFFFFFF),
                              height: 24 / 15,
                            ),
                            children: [
                              TextSpan(
                                text: widget.phone,
                                style: const TextStyle(
                                  color: AppColors.gold,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 26),

                        // OTP boxes
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              for (var i = 0; i < _otpLength; i++)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                  ),
                                  child: _buildOtpBox(i),
                                ),
                            ],
                          ),
                        ),
                        if (_error.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          Text(
                            _error,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFFEF4444),
                              fontSize: 13,
                            ),
                          ),
                        ],
                        const SizedBox(height: 26),

                        if (_loading)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.gold,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                t('auth.otpVerifying'),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0x8CFFFFFF),
                                ),
                              ),
                            ],
                          )
                        else
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: canVerify
                                    ? AppColors.gold
                                    : const Color(0x1AFFFFFF),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 15,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: canVerify ? _verify : null,
                              child: Text(
                                t('auth.otpVerify'),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: canVerify
                                      ? AppColors.navy
                                      : const Color(0x4DFFFFFF),
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 14),

                        TextButton(
                          onPressed: _resendTimer > 0 ? null : _handleResend,
                          child: Text(
                            _resendTimer > 0
                                ? t(
                                    'auth.otpResendAfter',
                                    vars: {'seconds': _resendTimer},
                                  )
                                : t('auth.otpResend'),
                            style: TextStyle(
                              fontSize: 14,
                              color: _resendTimer > 0
                                  ? const Color(0x4DFFFFFF)
                                  : AppColors.gold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpBox(int index) {
    final filled = _controllers[index].text.isNotEmpty;
    return SizedBox(
      width: 46,
      height: 56,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        enabled: !_loading,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (v) => _onChanged(index, v),
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: filled
              ? AppColors.gold.withAlpha(0x22)
              : const Color(0x12FFFFFF),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: filled
                  ? AppColors.gold
                  : _error.isNotEmpty
                  ? const Color(0xFFEF4444)
                  : const Color(0x2EFFFFFF),
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0x2EFFFFFF), width: 1.5),
          ),
        ),
      ),
    );
  }
}
