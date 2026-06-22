import 'package:flutter/material.dart';

import '../i18n/strings.dart';
import '../services/content_service.dart';
import '../theme/app_colors.dart';
import '../widgets/remote_builder.dart';
import '../widgets/service_card.dart';
import 'service_detail_screen.dart';

/// All-services grid, opened from the home tab "عرض الكل"
/// (ported from app/(tabs)/services.tsx).
class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
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
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t('services.screenTitle'),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      t('services.screenSubtitle'),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xA6FFFFFF),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: RemoteBuilder(
              load: ContentService.instance.services,
              onRetry: ContentService.instance.retryServices,
              emptyText: t('home.noServices'),
              builder: (context, services) => GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.95,
                ),
                itemCount: services.length,
                itemBuilder: (context, index) {
                  final service = services[index];
                  return ServiceCard(
                    service: service,
                    onPress: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            ServiceDetailScreen(serviceId: service.id),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
