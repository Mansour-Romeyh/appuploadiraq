import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../i18n/strings.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../widgets/auth_sheet.dart';
import '../widgets/join_lawyer_form.dart';

const _phone = '+964 786 900 8003';
const _email = 'info@justice-iq.org';
const _whatsapp = '9647869008003';

/// Office coordinates, resolved from the company's Google Maps pin
/// (https://maps.app.goo.gl/YgWfQVyBsw9bmLyD7 → "شركة ظل العدالة للمحاماة").
const officeLat = 33.2954188;
const officeLng = 44.3553345;

/// Canonical Google Maps link, used as the fallback when Waze isn't installed.
const officeMapsUrl = 'https://maps.app.goo.gl/YgWfQVyBsw9bmLyD7';

/// Waze deep link that launches turn-by-turn navigation to the office.
Uri officeWazeUri() =>
    Uri.parse('waze://?ll=$officeLat,$officeLng&navigate=yes');

/// Contact tab: quick actions, info, working hours, consultation form
/// (ported from app/(tabs)/contact.tsx).
class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  bool _sent = false;
  bool _submitting = false;
  String _error = '';
  Timer? _resetTimer;

  @override
  void dispose() {
    _resetTimer?.cancel();
    _nameController.dispose();
    _phoneController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _open(String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  /// Opens the office location in Waze; if Waze isn't installed, falls back to
  /// the Google Maps link so navigation still works.
  Future<void> _openLocation() async {
    final waze = officeWazeUri();
    try {
      if (await canLaunchUrl(waze)) {
        await launchUrl(waze, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {
      // Ignore and fall through to the maps fallback below.
    }
    await launchUrl(
      Uri.parse(officeMapsUrl),
      mode: LaunchMode.externalApplication,
    );
  }

  Future<void> _handleSubmit() async {
    if (_submitting) return;
    // Guests can book without signing in; when a user is logged in we pass
    // their token so the booking is stamped with their account.
    final token = AuthService.instance.user?.token;
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final subject = _subjectController.text.trim();
    final message = _messageController.text.trim();
    if (name.isEmpty || phone.isEmpty || subject.isEmpty) {
      setState(() => _error = t('contact.errorRequired'));
      return;
    }
    setState(() {
      _error = '';
      _submitting = true;
    });
    try {
      await ApiService.instance.createBooking(
        BookingPayload(
          fullName: name,
          phone: phone,
          subject: subject,
          message: message.isEmpty ? null : message,
        ),
        token,
      );
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      setState(() => _sent = true);
      _resetTimer = Timer(const Duration(seconds: 3), () {
        if (!mounted) return;
        setState(() {
          _sent = false;
          _nameController.clear();
          _phoneController.clear();
          _subjectController.clear();
          _messageController.clear();
        });
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      switch (e.code) {
        case ApiErrorCode.unauthorized:
          setState(() => _error = t('contact.sessionExpired'));
          showAuthSheet(context, actionLabel: t('contact.authAction'));
          break;
        case ApiErrorCode.throttled:
          setState(() => _error = t('contact.submitThrottled'));
          break;
        case ApiErrorCode.network:
        case ApiErrorCode.server:
          setState(() => _error = t('contact.submitFailed'));
          break;
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color: AppColors.navy,
          padding: EdgeInsets.only(
            top: topPadding + 16,
            left: 20,
            right: 20,
            bottom: 22,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t('contact.headerTitle'),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                t('contact.headerSub'),
                style: const TextStyle(fontSize: 14, color: Color(0xA6FFFFFF)),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              // Quick actions
              Row(
                children: [
                  _actionCard(
                    color: AppColors.navyLight,
                    icon: Icons.phone_outlined,
                    iconColor: Colors.white,
                    label: t('contact.call'),
                    labelColor: Colors.white,
                    onTap: () => _open('tel:${_phone.replaceAll(' ', '')}'),
                  ),
                  const SizedBox(width: 12),
                  _actionCard(
                    color: const Color(0xFF25D366),
                    icon: Icons.chat_bubble_outline,
                    iconColor: Colors.white,
                    label: t('contact.whatsapp'),
                    labelColor: Colors.white,
                    onTap: () => _open('https://wa.me/$_whatsapp'),
                  ),
                  const SizedBox(width: 12),
                  _actionCard(
                    color: AppColors.gold,
                    icon: Icons.mail_outline,
                    iconColor: AppColors.navy,
                    label: t('contact.emailAction'),
                    labelColor: AppColors.navy,
                    onTap: () => _open('mailto:$_email'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Info card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                  boxShadow: cardShadow,
                ),
                child: Column(
                  children: [
                    _infoRow(
                      Icons.phone_outlined,
                      t('contact.phoneLabel'),
                      _phone,
                    ),
                    const Divider(color: AppColors.border, height: 24),
                    _infoRow(
                      Icons.mail_outline,
                      t('contact.emailLabel'),
                      _email,
                    ),
                    const Divider(color: AppColors.border, height: 24),
                    _infoRow(
                      Icons.place_outlined,
                      t('contact.addressLabel'),
                      t('contact.address'),
                      onTap: _openLocation,
                      actionHint: t('contact.openInWaze'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Working hours
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                  boxShadow: cardShadow,
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.schedule,
                          size: 18,
                          color: AppColors.secondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          t('contact.workingHours'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.foreground,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _hoursRow(
                      t('contact.daysSatThu'),
                      t('contact.timeMorning'),
                      AppColors.foreground,
                    ),
                    const SizedBox(height: 12),
                    _hoursRow(
                      t('contact.friday'),
                      t('contact.closed'),
                      AppColors.foreground,
                    ),
                    const SizedBox(height: 12),
                    _hoursRow(
                      t('contact.emergency'),
                      '24/7',
                      AppColors.success,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Consultation form
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t('contact.formTitle'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.foreground,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      t('contact.formSubtitle'),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.mutedForeground,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_sent)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.success.withAlpha(0x18),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle_outline,
                              size: 22,
                              color: AppColors.success,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                t('contact.successMessage'),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.success,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else ...[
                      _formField(_nameController, t('contact.namePlaceholder')),
                      const SizedBox(height: 12),
                      _formField(
                        _phoneController,
                        t('contact.phonePlaceholder'),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 12),
                      _formField(
                        _subjectController,
                        t('contact.subjectPlaceholder'),
                      ),
                      const SizedBox(height: 12),
                      _formField(
                        _messageController,
                        t('contact.messagePlaceholder'),
                        maxLines: 4,
                      ),
                      if (_error.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          _error,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.destructive,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.navy,
                            disabledBackgroundColor: AppColors.navy.withAlpha(
                              0xB3,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _submitting ? null : _handleSubmit,
                          icon: _submitting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Icon(
                                  Icons.send,
                                  size: 16,
                                  color: Colors.white,
                                ),
                          label: Text(
                            t('contact.submit'),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Join-as-lawyer form
              const JoinLawyerForm(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _actionCard({
    required Color color,
    required IconData icon,
    required Color iconColor,
    required String label,
    required Color labelColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(14),
            boxShadow: cardShadow,
          ),
          child: Column(
            children: [
              Icon(icon, size: 22, color: iconColor),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: labelColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(
    IconData icon,
    String label,
    String value, {
    VoidCallback? onTap,
    String? actionHint,
  }) {
    final tappable = onTap != null;
    final row = Row(
      children: [
        SizedBox(
          width: 56,
          child: Column(
            children: [
              Icon(icon, size: 18, color: AppColors.secondary),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.mutedForeground,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: tappable ? AppColors.gold : AppColors.foreground,
                ),
              ),
              if (actionHint != null) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.near_me,
                      size: 13,
                      color: AppColors.gold,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      actionHint,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.gold,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        if (tappable)
          const Icon(
            Icons.chevron_left,
            size: 20,
            color: AppColors.mutedForeground,
          ),
      ],
    );
    if (!tappable) return row;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: row,
      ),
    );
  }

  Widget _hoursRow(String day, String time, Color timeColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          day,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.mutedForeground,
          ),
        ),
        Text(
          time,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: timeColor,
          ),
        ),
      ],
    );
  }

  Widget _formField(
    TextEditingController controller,
    String hint, {
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 14, color: AppColors.foreground),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.mutedForeground),
        filled: true,
        fillColor: AppColors.background,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.gold),
        ),
      ),
    );
  }
}
