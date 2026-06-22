import 'package:flutter/material.dart';

import '../i18n/strings.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import 'cases_screen.dart';
import 'office_intake_list_screen.dart';
import 'office_offer_list_screen.dart';

/// Office landing. Every signed-in user gets the Legal Cases entry; lawyers
/// additionally get the intake and offer workspace cards with live counts of
/// their own documents (ported from app/(tabs)/office.tsx). Counts load on
/// mount and reload after returning from either child list.
class OfficeHubScreen extends StatefulWidget {
  const OfficeHubScreen({super.key});

  @override
  State<OfficeHubScreen> createState() => _OfficeHubScreenState();
}

class _OfficeHubScreenState extends State<OfficeHubScreen> {
  int? _intakes;
  int? _offers;

  @override
  void initState() {
    super.initState();
    // Only lawyers have intake/offer documents; skip the calls for everyone else.
    if (AuthService.instance.isLawyer) _load();
  }

  Future<void> _load() async {
    final auth = AuthService.instance.user?.token;
    if (auth == null) return;
    try {
      final results = await Future.wait([
        ApiService.instance.lawyerListIntakes(auth),
        ApiService.instance.lawyerListOffers(auth),
      ]);
      if (!mounted) return;
      setState(() {
        _intakes = (results[0] as List).length;
        _offers = (results[1] as List).length;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _intakes = 0;
        _offers = 0;
      });
    }
  }

  Future<void> _open(Widget screen) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        top: topPadding + 24,
        left: 18,
        right: 18,
        bottom: 140,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t('office.hubTitle'),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.foreground,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AuthService.instance.isLawyer
                ? t('office.hubSubtitle')
                : t('office.hubSubtitleUser'),
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.mutedForeground,
            ),
          ),
          const SizedBox(height: 18),
          // Legal Cases — available to every signed-in user.
          _HubCard(
            icon: Icons.folder_outlined,
            title: t('cases.screenTitle'),
            subtitle: t('cases.hubCardSubtitle'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CasesScreen()),
            ),
          ),
          // Intake + offer workspaces are lawyer-only.
          if (AuthService.instance.isLawyer) ...[
            const SizedBox(height: 12),
            _HubCard(
              icon: Icons.description_outlined,
              title: t('office.intakeCard'),
              count: _intakes,
              onTap: () => _open(const OfficeIntakeListScreen()),
            ),
            const SizedBox(height: 12),
            _HubCard(
              icon: Icons.work_outline,
              title: t('office.offerCard'),
              count: _offers,
              onTap: () => _open(const OfficeOfferListScreen()),
            ),
          ],
        ],
      ),
    );
  }
}

class _HubCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final int? count;
  final String? subtitle;
  final VoidCallback onTap;

  const _HubCard({
    required this.icon,
    required this.title,
    this.count,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.gold),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, size: 26, color: AppColors.gold),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.foreground,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle ??
                        (count == null
                            ? '…'
                            : t('office.countOfMine', vars: {'n': count!})),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.gold,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_left,
              size: 22,
              color: AppColors.foreground,
            ),
          ],
        ),
      ),
    );
  }
}
