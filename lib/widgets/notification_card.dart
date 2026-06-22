import 'package:flutter/material.dart';

import '../i18n/tr.dart';
import '../models/app_notification.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';

/// Card widget for a single notification.
/// Ported from components/NotificationCard.tsx.
class NotificationCard extends StatelessWidget {
  final AppNotification item;

  const NotificationCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final meta = notificationTypeMeta(item.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.border, width: 1),
        borderRadius: BorderRadius.circular(14),
        boxShadow: cardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type icon circle
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: meta.color.withAlpha(0x18),
              shape: BoxShape.circle,
            ),
            child: Icon(meta.icon, size: 20, color: meta.color),
          ),
          const SizedBox(width: 12),
          // Content column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title row with optional unread dot
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        tr(item.title),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          height: 22 / 15,
                          color: AppColors.foreground,
                          fontWeight: item.read
                              ? FontWeight.w600
                              : FontWeight.w700,
                        ),
                      ),
                    ),
                    if (!item.read) ...[
                      const SizedBox(width: 8),
                      Container(
                        key: const ValueKey('unread-dot'),
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.gold,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                // Body text
                Text(
                  tr(item.body),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 20 / 13,
                    color: AppColors.mutedForeground,
                  ),
                ),
                const SizedBox(height: 6),
                // Date row
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
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
          ),
        ],
      ),
    );
  }
}
