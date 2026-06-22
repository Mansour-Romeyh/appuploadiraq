import 'package:flutter/material.dart';

import '../i18n/strings.dart';
import '../i18n/tr.dart';
import '../models/legal_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import 'feather_icons.dart';
import 'icon_3d.dart';

const double _iconSize = 24;
const double _iconContainer = 52;
const double _iconRadius = 14;

/// Service card with press-in scale + 3D icon animation
/// (ported from components/ServiceCard.tsx).
class ServiceCard extends StatefulWidget {
  final LegalService service;
  final VoidCallback onPress;
  final bool compact;

  const ServiceCard({
    super.key,
    required this.service,
    required this.onPress,
    this.compact = false,
  });

  @override
  State<ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<ServiceCard> {
  final Icon3DController _iconController = Icon3DController();
  bool _pressed = false;

  void _setPressed(bool pressed) {
    setState(() => _pressed = pressed);
    if (pressed) {
      _iconController.pressIn();
    } else {
      _iconController.pressOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.service;
    final color = parseHexColor(service.color);
    final title = tr(service.title);

    final icon = Icon3D(
      icon: featherIcon(service.icon),
      size: _iconSize,
      color: color,
      bgColor: color.withAlpha(0x25),
      containerSize: _iconContainer,
      borderRadius: _iconRadius,
      controller: _iconController,
    );

    final child = widget.compact
        ? Container(
            width: 104,
            margin: const EdgeInsetsDirectional.only(end: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(_iconRadius),
              border: Border.all(color: AppColors.border),
              boxShadow: cardShadow,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                icon,
                const SizedBox(height: 10),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.foreground,
                    height: 18 / 12,
                  ),
                ),
              ],
            ),
          )
        : Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
              boxShadow: cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                icon,
                const SizedBox(height: 14),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.foreground,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  tr(service.description),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.mutedForeground,
                    height: 20 / 13,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      t('services.readMore'),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.chevron_left,
                      size: 14,
                      color: AppColors.secondary,
                    ),
                  ],
                ),
              ],
            ),
          );

    return GestureDetector(
      onTap: widget.onPress,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? 0.91 : 1,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        child: child,
      ),
    );
  }
}
