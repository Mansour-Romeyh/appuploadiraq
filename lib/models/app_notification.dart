import 'package:flutter/material.dart';

import '../i18n/localized.dart';

/// Ported from law-firm-app/data/notifications.ts.
/// `case` is a reserved word in Dart — `caseUpdate` is the stable stand-in.
enum NotificationType { caseUpdate, appointment, news, system }

/// Stable type key → icon + accent color. Never changes with locale.
/// (Reference: NotificationCard.tsx typeMeta.)
({IconData icon, Color color}) notificationTypeMeta(NotificationType type) =>
    switch (type) {
      NotificationType.caseUpdate => (
        icon: Icons.work_outline,
        color: const Color(0xFF1565C0),
      ),
      NotificationType.appointment => (
        icon: Icons.calendar_today_outlined,
        color: const Color(0xFF2E7D32),
      ),
      NotificationType.news => (
        icon: Icons.description_outlined,
        color: const Color(0xFFF57F17),
      ),
      NotificationType.system => (
        icon: Icons.notifications_none,
        color: const Color(0xFF6A1B9A),
      ),
    };

class AppNotification {
  final String id;
  final NotificationType type;
  final Localized title;
  final Localized body;

  /// Display-as-is string, like news.date. Not localized.
  final String date;
  final bool read;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.date,
    required this.read,
  });
}
