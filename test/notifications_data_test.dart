import 'package:flutter_test/flutter_test.dart';

import 'package:dill_adala/data/notifications.dart';
import 'package:dill_adala/models/app_notification.dart';

void main() {
  test('seed data: 4 items, 2 unread, all types localized', () {
    expect(notifications, hasLength(4));
    expect(notifications.where((n) => !n.read), hasLength(2));
    expect(unreadCount, 2);
    expect(notifications.map((n) => n.type).toSet(), {
      NotificationType.caseUpdate,
      NotificationType.appointment,
      NotificationType.news,
      NotificationType.system,
    });
    for (final n in notifications) {
      expect(n.title.ar, isNotEmpty);
      expect(n.body.ar, isNotEmpty);
      expect(n.date, isNotEmpty);
    }
  });
}
