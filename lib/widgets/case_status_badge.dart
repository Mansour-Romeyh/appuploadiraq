import 'package:flutter/material.dart';

import '../i18n/strings.dart';
import '../models/case_item.dart';

/// Status pill for a case. `status` is the stable Arabic status key from the
/// backend. Known keys render a localized label (`cases.status.<key>`) with
/// their mapped color; unknown keys degrade to a neutral color and show the
/// raw backend label instead of a broken badge.
class CaseStatusBadge extends StatelessWidget {
  final String status;

  /// Raw backend label, shown when `status` isn't a known status key.
  final String? statusLabel;

  const CaseStatusBadge({super.key, required this.status, this.statusLabel});

  static const Color _fallbackColor = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    final known = CaseStatus.byKey(status);
    final color = known?.color ?? _fallbackColor;
    final label = known != null
        ? t('cases.status.$status')
        : (statusLabel?.isNotEmpty == true ? statusLabel! : status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(0x18),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
