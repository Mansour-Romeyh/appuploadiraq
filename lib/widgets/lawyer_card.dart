import 'package:flutter/material.dart';

import '../i18n/strings.dart';
import '../i18n/tr.dart';
import '../models/lawyer.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';

const List<Color> lawyerAvatarColors = [
  Color(0xFF1565C0),
  Color(0xFFC0392B),
  Color(0xFF2E7D32),
  Color(0xFF6A1B9A),
  Color(0xFF00838F),
];

Color lawyerAvatarColor(String id) =>
    lawyerAvatarColors[(int.tryParse(id) ?? 0) % lawyerAvatarColors.length];

/// Initials from a resolved (already-localized) name: first letter of the
/// second and third words — the first word is the honorific (e.g. "أ.").
String lawyerInitials(String resolvedName) {
  final words = resolvedName.split(' ').where((w) => w.isNotEmpty).toList();
  return words.skip(1).take(2).map((w) => w[0]).join();
}

/// Team list card (ported from components/LawyerCard.tsx): large photo (or
/// colored initials) at the start, info column, favorite heart pinned top-end,
/// and a "next available" footer bar.
class LawyerCard extends StatefulWidget {
  final Lawyer lawyer;
  final VoidCallback onPress;

  const LawyerCard({super.key, required this.lawyer, required this.onPress});

  @override
  State<LawyerCard> createState() => _LawyerCardState();
}

class _LawyerCardState extends State<LawyerCard> {
  bool _favorite = false;

  @override
  Widget build(BuildContext context) {
    final lawyer = widget.lawyer;
    final resolvedName = tr(lawyer.name);
    final photoUri = resolveMedia(lawyer.photoUrl);

    return GestureDetector(
      onTap: widget.onPress,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: cardShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Photo / initials avatar at the start edge.
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 96,
                        child: _avatar(lawyer, resolvedName, photoUri),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            resolvedName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.foreground,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tr(lawyer.title),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.mutedForeground,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success.withAlpha(0x22),
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.calendar_today_outlined,
                                  size: 12,
                                  color: AppColors.success,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  '${lawyer.experience} ${t('team.experienceUnit')}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.success,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Favorite pinned to the top-end corner.
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () => setState(() => _favorite = !_favorite),
                          child: Icon(
                            _favorite ? Icons.favorite : Icons.favorite_border,
                            size: 22,
                            color: _favorite
                                ? AppColors.destructive
                                : AppColors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Next-available footer.
            Container(
              decoration: const BoxDecoration(
                color: AppColors.muted,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.schedule,
                        size: 14,
                        color: AppColors.mutedForeground,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        t('team.nextAvailable'),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                  Flexible(
                    child: Text(
                      tr(lawyer.nextAvailable),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.gold,
                      ),
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

  Widget _avatar(Lawyer lawyer, String resolvedName, String photoUri) {
    if (photoUri.isNotEmpty) {
      // No explicit height: the avatar is already stretched to the card's
      // height by the Row's CrossAxisAlignment.stretch. Passing
      // height: double.infinity here gives the image an infinite intrinsic
      // height, which the enclosing IntrinsicHeight cannot resolve — in release
      // builds that fails silently and the whole card paints blank.
      return Image.network(
        photoUri,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _initialsBox(lawyer, resolvedName),
      );
    }
    return _initialsBox(lawyer, resolvedName);
  }

  Widget _initialsBox(Lawyer lawyer, String resolvedName) {
    return Container(
      constraints: const BoxConstraints(minHeight: 96),
      color: lawyerAvatarColor(lawyer.id),
      alignment: Alignment.center,
      child: Text(
        lawyerInitials(resolvedName),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 26,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
