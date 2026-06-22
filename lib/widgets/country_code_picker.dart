import 'package:flutter/material.dart';

import '../data/countries.dart';
import '../i18n/strings.dart';
import '../services/language_service.dart';

/// Slide-up searchable country dial-code picker
/// (ported from components/CountryCodePicker.tsx).
///
/// Returns the chosen [Country] via the future, or null if dismissed.
Future<Country?> showCountryCodePicker(
  BuildContext context, {
  required Country selected,
}) {
  return showModalBottomSheet<Country>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _CountryPickerSheet(selected: selected),
  );
}

class _CountryPickerSheet extends StatefulWidget {
  final Country selected;
  const _CountryPickerSheet({required this.selected});

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  final TextEditingController _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  List<Country> get _results {
    final q = _query.text.trim().toLowerCase();
    if (q.isEmpty) return countries;
    return countries
        .where(
          (c) =>
              c.nameAr.contains(_query.text.trim()) ||
              c.nameEn.toLowerCase().contains(q) ||
              c.dial.contains(q) ||
              c.iso.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = LanguageService.instance.lang.isRtl;
    final bottom = MediaQuery.of(context).padding.bottom;
    final results = _results;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      padding: EdgeInsets.only(top: 8, bottom: bottom + 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFDDDDDD),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    t('auth.countryPickerTitle'),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(
                    Icons.close,
                    size: 22,
                    color: Color(0xFF666666),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 46,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, size: 18, color: Color(0xFF999999)),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _query,
                    onChanged: (_) => setState(() {}),
                    textAlign: isRtl ? TextAlign.right : TextAlign.left,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF1A1A1A),
                    ),
                    decoration: InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      hintText: t('auth.countrySearchPlaceholder'),
                      hintStyle: const TextStyle(color: Color(0xFFAAAAAA)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: results.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Text(
                      t('auth.countryNoResults'),
                      style: const TextStyle(
                        color: Color(0xFF999999),
                        fontSize: 14,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: results.length,
                    itemBuilder: (context, i) {
                      final item = results[i];
                      final active =
                          item.iso == widget.selected.iso &&
                          item.dial == widget.selected.dial;
                      return InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => Navigator.of(context).pop(item),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 13,
                          ),
                          decoration: BoxDecoration(
                            color: active ? const Color(0xFFF1F5FF) : null,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Text(
                                item.flag,
                                style: const TextStyle(fontSize: 28),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  isRtl ? item.nameAr : item.nameEn,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: isRtl
                                      ? TextAlign.right
                                      : TextAlign.left,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF1A1A1A),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Text(
                                item.dial,
                                textDirection: TextDirection.ltr,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF555555),
                                ),
                              ),
                              if (active) ...[
                                const SizedBox(width: 10),
                                const Icon(
                                  Icons.check,
                                  size: 18,
                                  color: Color(0xFF1A2744),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
