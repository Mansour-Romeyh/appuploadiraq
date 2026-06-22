import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dill_adala/data/notifications.dart';
import 'package:dill_adala/screens/notifications_screen.dart';
import 'package:dill_adala/widgets/notification_card.dart';

void main() {
  testWidgets('notifications screen renders all seed cards', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: NotificationsScreen()));
    expect(find.byType(NotificationCard), findsNWidgets(notifications.length));
    // Unread cards show the gold dot; read ones don't (2 unread in seed data).
    expect(
      find.byKey(const ValueKey('unread-dot')),
      findsNWidgets(2),
    );
  });
}
