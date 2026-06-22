import 'package:flutter/material.dart';

import '../i18n/lang.dart';
import '../i18n/strings.dart';
import '../services/language_service.dart';
import '../theme/app_colors.dart';

/// Bottom-sheet language switcher. Lists the three languages by their native
/// names and applies the choice via LanguageService.
Future<void> showLanguagePicker(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      final active = LanguageService.instance.lang;
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                t('common.chooseLanguage'),
                style: const TextStyle(
                  color: AppColors.gold,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            for (final lang in langOrder)
              ListTile(
                title: Text(
                  langMeta[lang]!.native,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                trailing: lang == active
                    ? const Icon(Icons.check, color: AppColors.gold)
                    : null,
                onTap: () async {
                  await LanguageService.instance.setLang(lang);
                  if (context.mounted) Navigator.of(context).pop();
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}
