import 'package:flutter/material.dart';

import '../i18n/strings.dart';
import '../i18n/tr.dart';
import '../models/legal_service.dart';
import '../services/content_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../widgets/feather_icons.dart';
import '../widgets/icon_3d.dart';
import 'tabs_shell.dart';

/// Service detail page (ported from app/service/[id].tsx).
class ServiceDetailScreen extends StatelessWidget {
  final String serviceId;

  const ServiceDetailScreen({super.key, required this.serviceId});

  /// Switch the shell to the Contact tab, then pop back to it
  /// (reference routes to /(tabs)/contact).
  void _goToContact(BuildContext context) {
    final switcher = TabSwitcher.of(context);
    if (switcher != null) {
      switcher.switchTo(switcher.contactIndex);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: FutureBuilder<List<LegalService>>(
        future: ContentService.instance.services(),
        builder: (context, snap) {
          final service = (snap.data ?? const [])
              .where((s) => s.id == serviceId)
              .firstOrNull;
          final loading = snap.connectionState == ConnectionState.waiting;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                color: AppColors.navy,
                padding: EdgeInsets.only(
                  top: topPadding + 8,
                  left: 16,
                  right: 16,
                  bottom: 18,
                ),
                child: Row(
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
                        service == null ? '' : tr(service.title),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
              ),
              Expanded(
                child: loading
                    ? const Center(
                        child: CircularProgressIndicator(color: AppColors.gold),
                      )
                    : service == null
                    ? Center(
                        child: Text(
                          t('services.serviceNotFound'),
                          style: const TextStyle(color: AppColors.foreground),
                        ),
                      )
                    : _detailBody(
                        context,
                        service,
                        parseHexColor(service.color),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _detailBody(BuildContext context, LegalService service, Color color) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
      child: Column(
        children: [
          Icon3D(
            icon: featherIcon(service.icon),
            size: 40,
            color: color,
            bgColor: color.withAlpha(0x22),
            containerSize: 90,
            borderRadius: 24,
          ),
          const SizedBox(height: 16),
          Text(
            tr(service.title),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.foreground,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            tr(service.description),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.mutedForeground,
              height: 24 / 15,
            ),
          ),
          const SizedBox(height: 16),

          // About card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
              boxShadow: cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t('services.aboutService'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.foreground,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  tr(service.details),
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.mutedForeground,
                    height: 24 / 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Bullets card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
              boxShadow: cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      size: 18,
                      color: AppColors.gold,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      t('services.whatWeOffer'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.foreground,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                for (final bullet in service.bullets)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          margin: const EdgeInsets.only(top: 7),
                          decoration: const BoxDecoration(
                            color: AppColors.gold,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            tr(bullet),
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.mutedForeground,
                              height: 22 / 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Why us
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.goldLight,
              borderRadius: BorderRadius.circular(14),
              boxShadow: cardShadowSm,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.star_outline, size: 18, color: AppColors.gold),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t('services.whyChooseUs'),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.cream,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        t('services.whyChooseUsText'),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.cream,
                          height: 22 / 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.gold,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () => _goToContact(context),
              icon: const Icon(
                Icons.calendar_today_outlined,
                size: 18,
                color: AppColors.navy,
              ),
              label: Text(
                t('services.bookConsultation'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.navy,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
