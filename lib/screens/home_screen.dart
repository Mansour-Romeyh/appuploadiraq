import 'package:flutter/material.dart';

import '../i18n/strings.dart';
import '../models/legal_service.dart';
import '../models/news_item.dart';
import '../services/auth_service.dart';
import '../services/content_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../widgets/language_picker.dart';
import '../widgets/news_card.dart';
import '../widgets/section_header.dart';
import '../widgets/service_card.dart';
import '../data/notifications.dart' as notif;
import 'news_detail_screen.dart';
import 'news_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'service_detail_screen.dart';
import 'services_screen.dart';
import 'tabs_shell.dart';

/// Computes initials from a name: first letter of up to two words,
/// with '؟' as the fallback for an empty name.
String _initialsFor(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '؟';
  return parts.take(2).map((w) => w[0]).join();
}

/// Home tab (ported from app/(tabs)/index.tsx).
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final auth = AuthService.instance;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            color: AppColors.navy,
            padding: EdgeInsets.only(
              top: topPadding + 16,
              left: 20,
              right: 20,
              bottom: 24,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Flexible so a long firm name (English/Kurdish) yields
                    // space to the fixed-width controls instead of overflowing.
                    Expanded(
                      child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Profile entry — tap to view profile / sign out.
                        ListenableBuilder(
                          listenable: auth,
                          builder: (context, _) => GestureDetector(
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ProfileScreen(),
                              ),
                            ),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                color: AppColors.gold,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: auth.user != null
                                  ? Text(
                                      _initialsFor(auth.user!.name),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.navy,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.person,
                                      size: 20,
                                      color: AppColors.navy,
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t('common.company'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0x8CFFFFFF),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              t('common.firmShort'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                          ),
                        ),
                      ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.notifications_none,
                                color: Colors.white,
                              ),
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const NotificationsScreen(),
                                ),
                              ),
                              tooltip: t('notifications.screenTitle'),
                            ),
                            if (notif.unreadCount > 0)
                              PositionedDirectional(
                                top: 10,
                                end: 10,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.gold,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.language,
                            color: AppColors.gold,
                          ),
                          onPressed: () => showLanguagePicker(context),
                          tooltip: t('common.language'),
                        ),
                        const SizedBox(width: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            'assets/images/logo.jpg',
                            width: 52,
                            height: 52,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Hero banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0x0FFFFFFF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t('home.heroSlogan'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          height: 26 / 16,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.gold,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () => _goToContact(context),
                          child: Text(
                            t('freeConsultation'),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.navy,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Services
                SectionHeader(
                  title: t('home.legalServices'),
                  onSeeAll: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ServicesScreen()),
                  ),
                ),
                SizedBox(
                  height: 124,
                  child: FutureBuilder<List<LegalService>>(
                    future: ContentService.instance.services(),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.gold,
                          ),
                        );
                      }
                      final services = snap.data ?? const <LegalService>[];
                      if (services.isEmpty) {
                        return Center(
                          child: Text(
                            t('home.noServices'),
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.mutedForeground,
                            ),
                          ),
                        );
                      }
                      return ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          for (final s in services.take(6))
                            ServiceCard(
                              service: s,
                              compact: true,
                              onPress: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ServiceDetailScreen(serviceId: s.id),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // News
                SectionHeader(
                  title: t('home.legalNews'),
                  onSeeAll: () => Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => const NewsScreen())),
                ),
                FutureBuilder<List<NewsItem>>(
                  future: ContentService.instance.news(),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.gold,
                          ),
                        ),
                      );
                    }
                    final newsItems = snap.data ?? const <NewsItem>[];
                    if (newsItems.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            t('home.noNews'),
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.mutedForeground,
                            ),
                          ),
                        ),
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final item in newsItems.take(2))
                          NewsCard(
                            item: item,
                            onPress: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    NewsDetailScreen(newsId: item.id),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 10),

                // Quick contact banner
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                    boxShadow: cardShadow,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t('home.needLegalHelp'),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.foreground,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            t('home.availableAlways'),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.mutedForeground,
                            ),
                          ),
                        ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.gold,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () => _goToContact(context),
                        icon: const Icon(
                          Icons.phone_outlined,
                          size: 16,
                          color: AppColors.navy,
                        ),
                        label: Text(
                          t('home.callNow'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.navy,
                          ),
                        ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // User info + logout
                Container(
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: AppColors.border)),
                  ),
                  padding: const EdgeInsets.only(top: 20),
                  child: ListenableBuilder(
                    listenable: auth,
                    builder: (context, _) => Column(
                      children: [
                        if (auth.user != null)
                          Text(
                            t('home.greeting', vars: {'name': auth.user!.name}),
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.mutedForeground,
                            ),
                          ),
                        if (auth.isGuest)
                          Text(
                            t('home.browsingAsGuest'),
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.mutedForeground,
                            ),
                          ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.border),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => auth.logout(),
                          icon: const Icon(
                            Icons.logout,
                            size: 16,
                            color: AppColors.destructive,
                          ),
                          label: Text(
                            t('home.logout'),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.destructive,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _goToContact(BuildContext context) {
    final switcher = TabSwitcher.of(context);
    if (switcher != null) switcher.switchTo(switcher.contactIndex);
  }
}
