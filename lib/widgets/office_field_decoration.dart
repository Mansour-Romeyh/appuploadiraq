import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Gold-outlined input decoration shared by the office create forms.
InputDecoration officeFieldDecoration(String hint) => InputDecoration(
  hintText: hint,
  hintStyle: const TextStyle(color: AppColors.mutedForeground),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: AppColors.gold),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
  ),
  contentPadding: const EdgeInsets.all(12),
);

/// Tap-to-pick pseudo-input showing the current selection or its placeholder.
class PickerField extends StatelessWidget {
  final String value;
  final String placeholder;
  final VoidCallback onTap;

  const PickerField({
    super.key,
    required this.value,
    required this.placeholder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.gold),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          value.isNotEmpty ? value : placeholder,
          style: TextStyle(
            color: value.isNotEmpty
                ? AppColors.foreground
                : AppColors.mutedForeground,
          ),
        ),
      ),
    );
  }
}
