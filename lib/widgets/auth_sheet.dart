import 'package:flutter/material.dart';

import '../i18n/strings.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';

/// Bottom sheet shown to guests when a feature requires login
/// (ported from components/AuthSheet.tsx). Logging out sends the
/// user back to the login screen via the AuthGate.
Future<void> showAuthSheet(BuildContext context, {String? actionLabel}) {
  final resolvedAction = actionLabel ?? t('auth.sheetDefaultAction');
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) => Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(sheetContext).padding.bottom + 32,
      ),
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.gold.withAlpha(0x18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_outline,
              size: 28,
              color: AppColors.gold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            t('auth.sheetTitle'),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.foreground,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            t('auth.sheetSubtitle', vars: {'action': resolvedAction}),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.mutedForeground,
              height: 22 / 14,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.navyLight,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () async {
                Navigator.of(sheetContext).pop();
                await AuthService.instance.logout();
              },
              icon: const Icon(
                Icons.person_outline,
                size: 18,
                color: Colors.white,
              ),
              label: Text(
                t('auth.sheetLogin'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: () => Navigator.of(sheetContext).pop(),
            child: Text(
              t('auth.sheetNotNow'),
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.mutedForeground,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
