import 'package:flutter/material.dart';

import '../i18n/strings.dart';
import '../models/office.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';

/// Detail / submit view for a single intake document
/// (ported from app/office/intake/[id].tsx).
class OfficeIntakeDetailScreen extends StatefulWidget {
  final String name;

  const OfficeIntakeDetailScreen({super.key, required this.name});

  @override
  State<OfficeIntakeDetailScreen> createState() =>
      _OfficeIntakeDetailScreenState();
}

class _OfficeIntakeDetailScreenState extends State<OfficeIntakeDetailScreen> {
  IntakeDoc? _doc;
  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = AuthService.instance.user?.token;
    if (auth == null) {
      if (mounted) setState(() { _doc = null; _loading = false; });
      return;
    }
    if (mounted) setState(() => _loading = true);
    try {
      final doc = await ApiService.instance.lawyerGetIntake(widget.name, auth);
      if (!mounted) return;
      setState(() { _doc = doc; _loading = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() { _doc = null; _loading = false; });
    }
  }

  Future<void> _confirmSubmit() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        content: Text(
          t('office.confirmSubmit'),
          style: const TextStyle(color: AppColors.foreground),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              '×',
              style: TextStyle(color: AppColors.mutedForeground),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              t('office.submit'),
              style: const TextStyle(color: AppColors.gold),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) await _submit();
  }

  Future<void> _submit() async {
    final auth = AuthService.instance.user?.token;
    if (auth == null) return;
    setState(() => _submitting = true);
    try {
      await ApiService.instance.lawyerSubmitIntake(widget.name, auth);
      await _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t('office.saveFailed'))),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.gold),
        ),
      );
    }

    final topPadding = MediaQuery.of(context).padding.top;

    if (_doc == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Padding(
            padding: EdgeInsets.only(top: topPadding + 40),
            child: Text(
              t('office.loadFailed'),
              style: const TextStyle(color: AppColors.mutedForeground),
            ),
          ),
        ),
      );
    }

    final doc = _doc!;
    final isSubmitted = doc.docstatus == 1;

    final clientNames = doc.clients
        .map((c) => c.customerFullName ?? c.client ?? '')
        .where((s) => s.isNotEmpty)
        .join('، ');
    final defendantNames = doc.defendants
        .map((d) => d.customerFullName ?? d.client ?? '')
        .where((s) => s.isNotEmpty)
        .join('، ');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          top: topPadding + 16,
          left: 18,
          right: 18,
          bottom: 140,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Color(0x26FFFFFF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    doc.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.foreground,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isSubmitted
                        ? AppColors.gold
                        : const Color(0x26FFFFFF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    isSubmitted
                        ? t('office.submitted')
                        : t('office.draft'),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSubmitted
                          ? AppColors.navy
                          : AppColors.foreground,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _Field(label: t('office.date'), value: doc.postingDate),
            _Field(
              label: t('office.item'),
              value: doc.itemName ?? doc.item,
            ),
            _Field(label: t('office.clients'), value: clientNames),
            _Field(label: t('office.defendants'), value: defendantNames),
            if (doc.docstatus == 0)
              FilledButton(
                onPressed: _submitting ? null : _confirmSubmit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  _submitting ? t('office.saving') : t('office.submit'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final String? value;

  const _Field({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.mutedForeground,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value!,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.foreground,
            ),
          ),
        ],
      ),
    );
  }
}
