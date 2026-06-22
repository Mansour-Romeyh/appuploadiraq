import 'package:flutter/material.dart';

import '../i18n/strings.dart';
import '../models/office.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import 'office_intake_detail_screen.dart';
import 'office_intake_new_screen.dart';

/// List of the lawyer's own intake documents
/// (ported from app/office/intake/index.tsx).
class OfficeIntakeListScreen extends StatefulWidget {
  const OfficeIntakeListScreen({super.key});

  @override
  State<OfficeIntakeListScreen> createState() => _OfficeIntakeListScreenState();
}

class _OfficeIntakeListScreenState extends State<OfficeIntakeListScreen> {
  List<IntakeListItem> _rows = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = AuthService.instance.user?.token;
    if (auth == null) {
      if (mounted) setState(() { _rows = []; _loading = false; });
      return;
    }
    if (mounted) setState(() => _loading = true);
    try {
      final rows = await ApiService.instance.lawyerListIntakes(auth);
      if (!mounted) return;
      setState(() { _rows = rows; _loading = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() { _rows = []; _loading = false; });
    }
  }

  Future<void> _push(Widget screen) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: EdgeInsets.only(top: topPadding + 16),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Color(0x26FFFFFF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      t('office.intakeCard'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.foreground,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _push(const OfficeIntakeNewScreen()),
                    icon: const Icon(Icons.add, color: AppColors.gold),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.gold),
                    )
                  : _rows.isEmpty
                      ? Center(
                          child: Text(
                            t('office.emptyIntakes'),
                            style: const TextStyle(
                              color: AppColors.mutedForeground,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 140),
                          itemCount: _rows.length,
                          itemBuilder: (context, i) =>
                              _IntakeRow(
                                item: _rows[i],
                                onTap: () => _push(
                                  OfficeIntakeDetailScreen(name: _rows[i].name),
                                ),
                              ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IntakeRow extends StatelessWidget {
  final IntakeListItem item;
  final VoidCallback onTap;

  const _IntakeRow({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isSubmitted = item.docstatus == 1;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.gold),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (item.clientNames != null && item.clientNames!.isNotEmpty)
                        ? item.clientNames!
                        : item.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.foreground,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.itemName ?? ''} · ${item.postingDate}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isSubmitted ? AppColors.gold : const Color(0x26FFFFFF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                isSubmitted
                    ? t('office.submitted')
                    : t('office.draft'),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isSubmitted ? AppColors.navy : AppColors.foreground,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
