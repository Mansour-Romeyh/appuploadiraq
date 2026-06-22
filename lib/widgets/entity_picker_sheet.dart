import 'dart:async';

import 'package:flutter/material.dart';

import '../i18n/strings.dart';
import '../theme/app_colors.dart';

/// One selectable row in the picker.
class PickerOption {
  final String id;
  final String label;
  final String? sublabel;
  final num? meta;

  const PickerOption({
    required this.id,
    required this.label,
    this.sublabel,
    this.meta,
  });
}

/// Opens the generic typeahead bottom sheet.
/// Ported from components/office/EntityPickerModal.tsx:
///  - results cached per query for the session (instant on reopen/re-type),
///  - the default (empty-query) list loads immediately; typing debounces 250ms,
///  - previous rows stay on screen while the next query loads.
/// [cacheScope] namespaces the cache per picker use-site; append [cacheKey]
/// when the same picker can return different sets (items scoped by group).
Future<void> showEntityPicker(
  BuildContext context, {
  required String title,
  required Future<List<PickerOption>> Function(String q) search,
  required void Function(PickerOption option) onPick,
  String cacheScope = '',
  String cacheKey = '',
  String? emptyText,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  builder: (sheetContext) => EntityPickerSheet(
    title: title,
    search: search,
    onPick: (o) {
      onPick(o);
      Navigator.of(sheetContext).pop();
    },
    cacheScope: cacheScope,
    cacheKey: cacheKey,
    emptyText: emptyText,
  ),
);

class EntityPickerSheet extends StatefulWidget {
  final String title;
  final Future<List<PickerOption>> Function(String q) search;
  final void Function(PickerOption option) onPick;
  final String cacheScope;
  final String cacheKey;
  final String? emptyText;

  const EntityPickerSheet({
    super.key,
    required this.title,
    required this.search,
    required this.onPick,
    this.cacheScope = '',
    this.cacheKey = '',
    this.emptyText,
  });

  /// Session-scoped result cache shared across opens (the reference keeps it
  /// in a useRef on a component that stays mounted; a sheet remounts per open,
  /// so the cache must be static to survive).
  static final Map<String, List<PickerOption>> _cache = {};

  static void clearCacheForTest() => _cache.clear();

  @override
  State<EntityPickerSheet> createState() => _EntityPickerSheetState();
}

class _EntityPickerSheetState extends State<EntityPickerSheet> {
  final TextEditingController _query = TextEditingController();
  List<PickerOption> _rows = const [];
  bool _loading = false;
  Timer? _debounce;
  int _generation = 0;

  String get _cacheKeyFor =>
      '${widget.cacheScope} ${widget.cacheKey} ${_query.text.trim()}';

  @override
  void initState() {
    super.initState();
    _run(immediate: true);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  void _onChanged(String _) => _run();

  void _run({bool immediate = false}) {
    _debounce?.cancel();

    final cached = EntityPickerSheet._cache[_cacheKeyFor];
    if (cached != null) {
      setState(() {
        _rows = cached;
        _loading = false;
      });
      return;
    }

    setState(() => _loading = true);
    final gen = ++_generation;
    // Default (empty) list loads at once; typing is debounced.
    final delay = (immediate || _query.text.trim().isEmpty)
        ? Duration.zero
        : const Duration(milliseconds: 250);
    _debounce = Timer(delay, () async {
      final key = _cacheKeyFor;
      List<PickerOption> result;
      try {
        result = await widget.search(_query.text);
      } catch (_) {
        result = const [];
      }
      if (!mounted || gen != _generation) return;
      EntityPickerSheet._cache[key] = result;
      setState(() {
        _rows = result;
        _loading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final maxHeight = MediaQuery.of(context).size.height * 0.82;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight, minHeight: 300),
        decoration: const BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 5,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.foreground,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.close,
                    size: 18,
                    color: AppColors.mutedForeground,
                  ),
                  style: IconButton.styleFrom(backgroundColor: AppColors.muted),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: AppColors.muted,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.search,
                    size: 18,
                    color: AppColors.mutedForeground,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _query,
                      onChanged: _onChanged,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: t('office.search'),
                        hintStyle:
                            const TextStyle(color: AppColors.mutedForeground),
                        border: InputBorder.none,
                        isCollapsed: true,
                      ),
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.foreground,
                      ),
                    ),
                  ),
                  if (_loading)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.gold,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Flexible(
              child: _loading && _rows.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.only(top: 28),
                      child: CircularProgressIndicator(color: AppColors.gold),
                    )
                  : _rows.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.only(top: 28),
                          child: Text(
                            widget.emptyText ?? t('office.noResults'),
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.mutedForeground,
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: _rows.length,
                          separatorBuilder: (context, index) => const Divider(
                            height: 1,
                            thickness: 0.5,
                            color: AppColors.border,
                          ),
                          itemBuilder: (context, i) {
                            final option = _rows[i];
                            return InkWell(
                              onTap: () => widget.onPick(option),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            option.label,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.foreground,
                                            ),
                                          ),
                                          if (option.sublabel != null &&
                                              option.sublabel!.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 2),
                                              child: Text(
                                                option.sublabel!,
                                                maxLines: 1,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 12.5,
                                                  color: AppColors
                                                      .mutedForeground,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.chevron_left,
                                      size: 20,
                                      color: AppColors.gold,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
