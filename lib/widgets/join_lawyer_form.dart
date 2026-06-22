import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../i18n/strings.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import 'auth_sheet.dart';

final RegExp _iraqiPhoneRe = RegExp(r'^07\d{9}$');
const int _minGraduationYear = 1950;
const Set<String> _allowedIdExtensions = {'jpg', 'jpeg', 'png', 'webp', 'heic'};
const int _maxIdFileBytes = 5 * 1024 * 1024;

/// "انضم الى فريقنا كمحامي" application card, shown below the booking form on
/// the contact tab. Same auth gating + error mapping as the booking form
/// (ported from components/JoinLawyerForm.tsx).
class JoinLawyerForm extends StatefulWidget {
  const JoinLawyerForm({super.key});

  @override
  State<JoinLawyerForm> createState() => _JoinLawyerFormState();
}

class _PickedId {
  final Uint8List bytes;
  final String base64;
  final String filename;
  const _PickedId({
    required this.bytes,
    required this.base64,
    required this.filename,
  });
}

class _JoinLawyerFormState extends State<JoinLawyerForm> {
  final _picker = ImagePicker();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _gradYearController = TextEditingController();
  final _universityController = TextEditingController();
  final _jobController = TextEditingController();
  _PickedId? _idImage;
  bool _sent = false;
  bool _submitting = false;
  String _error = '';
  Timer? _resetTimer;

  @override
  void dispose() {
    _resetTimer?.cancel();
    _nameController.dispose();
    _phoneController.dispose();
    _gradYearController.dispose();
    _universityController.dispose();
    _jobController.dispose();
    super.dispose();
  }

  Future<void> _pickIdImage() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (image == null) return;
    final bytes = await image.readAsBytes();
    if (!mounted) return;
    final filename = image.name.isNotEmpty ? image.name : 'lawyer-id.jpg';
    final ext = filename.contains('.')
        ? filename.split('.').last.toLowerCase()
        : '';
    // Mirror the server's 5 MB cap so rejects happen before megabytes upload.
    if (!_allowedIdExtensions.contains(ext) || bytes.length > _maxIdFileBytes) {
      setState(() => _error = t('contact.joinFileInvalid'));
      return;
    }
    setState(() {
      _error = '';
      _idImage = _PickedId(
        bytes: bytes,
        base64: base64Encode(bytes),
        filename: filename,
      );
    });
    HapticFeedback.lightImpact();
  }

  Future<void> _handleSubmit() async {
    if (_submitting) return;
    // Guests can apply without signing in; a logged-in user's token is passed
    // so the request is stamped with their account.
    final token = AuthService.instance.user?.token;
    final name = _nameController.text.trim();
    final cleanPhone = _phoneController.text.replaceAll(RegExp(r'[\s-]'), '');
    if (name.isEmpty || cleanPhone.isEmpty) {
      setState(() => _error = t('contact.errorRequired'));
      return;
    }
    if (!_iraqiPhoneRe.hasMatch(cleanPhone)) {
      setState(() => _error = t('contact.joinPhoneInvalid'));
      return;
    }
    final yearText = _gradYearController.text.trim();
    int? year;
    if (yearText.isNotEmpty) {
      year = int.tryParse(yearText);
      if (year == null ||
          year < _minGraduationYear ||
          year > DateTime.now().year) {
        setState(() => _error = t('contact.joinYearInvalid'));
        return;
      }
    }
    final university = _universityController.text.trim();
    final job = _jobController.text.trim();
    setState(() {
      _error = '';
      _submitting = true;
    });
    try {
      await ApiService.instance.createJoinRequest(
        JoinRequestPayload(
          fullName: name,
          phone: cleanPhone,
          graduationYear: year,
          university: university.isEmpty ? null : university,
          currentJob: job.isEmpty ? null : job,
          idFileBase64: _idImage?.base64,
          idFilename: _idImage?.filename,
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
          _gradYearController.clear();
          _universityController.clear();
          _jobController.clear();
          _idImage = null;
        });
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      switch (e.code) {
        case ApiErrorCode.unauthorized:
          setState(() => _error = t('contact.sessionExpired'));
          showAuthSheet(context, actionLabel: t('contact.joinAuthAction'));
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
    return Container(
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
            t('contact.joinTitle'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.foreground,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            t('contact.joinSubtitle'),
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
            _field(_nameController, t('contact.namePlaceholder')),
            const SizedBox(height: 12),
            _field(
              _phoneController,
              t('contact.phonePlaceholder'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            _field(
              _gradYearController,
              t('contact.joinGradYearPlaceholder'),
              keyboardType: TextInputType.number,
              maxLength: 4,
            ),
            const SizedBox(height: 12),
            _field(_universityController, t('contact.joinUniversityPlaceholder')),
            const SizedBox(height: 12),
            _field(_jobController, t('contact.joinJobPlaceholder')),
            const SizedBox(height: 12),
            if (_idImage != null)
              Align(
                alignment: Alignment.center,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.memory(
                        _idImage!.bytes,
                        width: 96,
                        height: 96,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: -6,
                      right: -6,
                      child: GestureDetector(
                        onTap: () => setState(() => _idImage = null),
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: const BoxDecoration(
                            color: AppColors.destructive,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              GestureDetector(
                onTap: _pickIdImage,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.border,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.attach_file,
                        size: 16,
                        color: AppColors.secondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        t('contact.joinAttachId'),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
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
                  disabledBackgroundColor: AppColors.navy.withAlpha(0xB3),
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
                    : const Icon(Icons.send, size: 16, color: Colors.white),
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
    );
  }

  Widget _field(
    TextEditingController controller,
    String hint, {
    TextInputType? keyboardType,
    int? maxLength,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      style: const TextStyle(fontSize: 14, color: AppColors.foreground),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.mutedForeground),
        filled: true,
        fillColor: AppColors.background,
        counterText: '',
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
