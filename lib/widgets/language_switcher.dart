import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../i18n/lang.dart';
import '../i18n/strings.dart';
import '../services/language_service.dart';
import '../theme/app_colors.dart';

/// Three-way segmented control for choosing the app language
/// (العربية / English / کوردی). Switching is live — it flips layout direction
/// and re-translates the whole app immediately. Ported from
/// components/LanguageSwitcher.tsx; this is the in-app language control that
/// lives on the Contact tab.
class LanguageSwitcher extends StatelessWidget {
  const LanguageSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final service = LanguageService.instance;
    final current = service.lang;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.language, size: 16, color: AppColors.gold),
            const SizedBox(width: 8),
            Text(
              t('common.chooseLanguage'),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.cream,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppColors.navyLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              for (final code in langOrder)
                Expanded(
                  child: _Segment(
                    label: langMeta[code]!.native,
                    active: code == current,
                    onTap: () {
                      if (code == current) return;
                      HapticFeedback.selectionClick();
                      service.setLang(code);
                    },
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Segment extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _Segment({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? AppColors.gold : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 14,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? AppColors.navy : AppColors.mutedForeground,
          ),
        ),
      ),
    );
  }
}
