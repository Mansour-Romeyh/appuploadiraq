import 'package:flutter/material.dart';

import '../i18n/strings.dart';
import '../i18n/tr.dart';
import '../models/news_item.dart';
import '../services/content_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../theme/news_category.dart';

/// News article page with hero image + related news
/// (ported from app/news/[id].tsx).
class NewsDetailScreen extends StatelessWidget {
  final String newsId;

  const NewsDetailScreen({super.key, required this.newsId});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Sticky navbar
          Container(
            color: AppColors.navy,
            padding: EdgeInsets.only(top: topPadding, left: 16, right: 16),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        Icons.arrow_forward,
                        size: 22,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      t('news.navTitle'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: FutureBuilder<List<NewsItem>>(
              future: ContentService.instance.news(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.gold),
                  );
                }
                final list = snap.data ?? const <NewsItem>[];
                final item = list.where((n) => n.id == newsId).firstOrNull;
                if (item == null) {
                  return Center(
                    child: Text(
                      t('news.notFound'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: AppColors.foreground,
                      ),
                    ),
                  );
                }
                final catColor = newsCategoryColor(item.category);
                final related = list
                    .where((n) => n.id != item.id)
                    .take(3)
                    .toList();
                return ListView(
                  padding: const EdgeInsets.only(bottom: 100),
                  children: [
                    // Hero
                    Stack(
                      children: [
                        Positioned.fill(
                          child: Image.network(
                            item.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(color: AppColors.muted),
                          ),
                        ),
                        Positioned.fill(
                          child: Container(color: const Color(0x85000000)),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 32, 20, 28),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Align(
                                alignment: AlignmentDirectional.centerEnd,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: catColor,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    tr(item.categoryLabel),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                tr(item.title),
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  height: 36 / 22,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today_outlined,
                                    size: 13,
                                    color: Color(0xA6FFFFFF),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    item.date,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xA6FFFFFF),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Content card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
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
                                      Icons.description_outlined,
                                      size: 16,
                                      color: AppColors.secondary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      t('news.articleDetails'),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.foreground,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  tr(item.content),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: AppColors.foreground,
                                    height: 28 / 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          Text(
                            t('news.relatedNews'),
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppColors.foreground,
                            ),
                          ),
                          const SizedBox(height: 14),

                          for (final relatedItem in related)
                            _RelatedCard(
                              item: relatedItem,
                              onTap: () =>
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (_) => NewsDetailScreen(
                                        newsId: relatedItem.id,
                                      ),
                                    ),
                                  ),
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RelatedCard extends StatelessWidget {
  final NewsItem item;
  final VoidCallback onTap;

  const _RelatedCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final rc = newsCategoryColor(item.category);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: rc.withAlpha(0x20),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    tr(item.categoryLabel),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: rc,
                    ),
                  ),
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 11,
                      color: AppColors.mutedForeground,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      item.date,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              tr(item.title),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.foreground,
                height: 22 / 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              tr(item.summary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.mutedForeground,
                height: 20 / 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
