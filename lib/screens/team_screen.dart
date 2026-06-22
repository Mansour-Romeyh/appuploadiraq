import 'package:flutter/material.dart';

import '../i18n/strings.dart';
import '../services/content_service.dart';
import '../theme/app_colors.dart';
import '../widgets/lawyer_card.dart';
import '../widgets/remote_builder.dart';
import 'lawyer_detail_screen.dart';

/// Team tab (ported from app/(tabs)/team.tsx).
class TeamScreen extends StatelessWidget {
  const TeamScreen({super.key});

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
                t('team.screenTitle'),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                t('team.screenSubtitle'),
                style: const TextStyle(fontSize: 14, color: Color(0xA6FFFFFF)),
              ),
            ],
          ),
        ),
        Expanded(
          child: RemoteBuilder(
            load: ContentService.instance.team,
            onRetry: ContentService.instance.retryTeam,
            emptyText: t('team.notFound'),
            builder: (context, lawyers) => ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                for (final lawyer in lawyers)
                  LawyerCard(
                    lawyer: lawyer,
                    onPress: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => LawyerDetailScreen(lawyerId: lawyer.id),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
