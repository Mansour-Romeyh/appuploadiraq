import 'package:flutter/material.dart';

import '../i18n/tr.dart';
import '../models/news_item.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../theme/news_category.dart';

class NewsCard extends StatelessWidget {
  final NewsItem item;
  final VoidCallback? onPress;

  const NewsCard({super.key, required this.item, this.onPress});

  @override
  Widget build(BuildContext context) {
    final catColor = newsCategoryColor(item.category);

    return GestureDetector(
      onTap: onPress,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          boxShadow: cardShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Image.network(
              item.imageUrl,
              height: 160,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 160,
                color: AppColors.muted,
                child: const Icon(
                  Icons.image_outlined,
                  color: AppColors.mutedForeground,
                  size: 40,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: catColor.withAlpha(0x18),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          tr(item.categoryLabel),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: catColor,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 12,
                            color: AppColors.mutedForeground,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            item.date,
                            style: const TextStyle(
                              fontSize: 12,
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
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.foreground,
                      height: 22 / 15,
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
          ],
        ),
      ),
    );
  }
}
