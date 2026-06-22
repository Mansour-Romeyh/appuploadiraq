import 'package:flutter/material.dart';

import '../i18n/strings.dart';
import '../models/case_item.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/language_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../widgets/case_status_badge.dart';

/// Cases tab: a read-only viewer of the signed-in user's cases fetched from the
/// backend (ported from app/(tabs)/cases.tsx). Pull-to-refresh re-fetches; the
/// filter bar only appears when more than one distinct status is present.
class CasesScreen extends StatefulWidget {
  const CasesScreen({super.key});

  @override
  State<CasesScreen> createState() => _CasesScreenState();
}

class _CasesScreenState extends State<CasesScreen> {
  List<RemoteCase> _cases = [];
  bool _loading = true;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = AuthService.instance.user?.token;
    // No usable credentials — show the sign-in empty state instead of calling
    // the API (the tab itself is guest-gated elsewhere).
    if (token == null) {
      if (mounted) {
        setState(() {
          _cases = [];
          _loading = false;
        });
      }
      return;
    }
    try {
      final rows = await ApiService.instance.getMyCases(token);
      if (mounted) setState(() => _cases = rows);
    } on ApiException {
      if (mounted) setState(() => _cases = []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refresh() async {
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    // Reached as a pushed route from the Office hub (no longer a tab), so it
    // owns its Scaffold and offers a back affordance in the header.
    return ListenableBuilder(
      listenable: LanguageService.instance,
      builder: (context, _) => Scaffold(
        backgroundColor: AppColors.background,
        body: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final hasToken = AuthService.instance.user?.token != null;

    // Only offer filters for statuses that actually appear, in canonical order.
    final presentStatuses = kStatusOptions
        .where((s) => _cases.any((c) => c.status == s))
        .toList();
    final showFilters = presentStatuses.length > 1;
    final filtered = _filter == 'all'
        ? _cases
        : _cases.where((c) => c.status == _filter).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Container(
          color: AppColors.navy,
          padding: EdgeInsets.only(
            top: topPadding + 16,
            left: 20,
            right: 20,
            bottom: 18,
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
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
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t('cases.screenTitle'),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      t('cases.casesCount', vars: {'n': _cases.length}),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xA6FFFFFF),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Filter chips (hidden unless >1 distinct status present)
        if (showFilters)
          Container(
            decoration: const BoxDecoration(
              color: AppColors.card,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  for (final s in ['all', ...presentStatuses])
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _filter = s),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _filter == s
                                ? AppColors.navyLight
                                : AppColors.muted,
                            borderRadius: BorderRadius.circular(20),
                            border: _filter == s
                                ? Border.all(color: AppColors.gold)
                                : null,
                          ),
                          child: Text(
                            s == 'all'
                                ? t('cases.filterAll')
                                : t('cases.status.$s'),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: _filter == s
                                  ? Colors.white
                                  : AppColors.mutedForeground,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

        // Body
        Expanded(
          child: _loading
              ? _buildLoading()
              : !hasToken
              ? _buildSignInEmpty()
              : RefreshIndicator(
                  onRefresh: _refresh,
                  color: AppColors.gold,
                  backgroundColor: AppColors.card,
                  child: filtered.isEmpty
                      ? _buildEmpty()
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) =>
                              _buildCaseCard(filtered[index]),
                        ),
                ),
        ),
      ],
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.gold),
          const SizedBox(height: 12),
          Text(
            t('cases.loading'),
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }

  /// Scrollable so pull-to-refresh works even when the list is empty.
  Widget _buildEmpty() {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 60),
              const Icon(
                Icons.folder_outlined,
                size: 48,
                color: AppColors.mutedForeground,
              ),
              const SizedBox(height: 12),
              Text(
                t('cases.emptyTitle'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.foreground,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                t('cases.emptyText'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.mutedForeground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Friendly "sign in to view your cases" state when there's no usable token.
  Widget _buildSignInEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lock_outline,
              size: 48,
              color: AppColors.mutedForeground,
            ),
            const SizedBox(height: 12),
            Text(
              t('auth.sheetTitle'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.foreground,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              t('auth.guestHint'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.mutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaseCard(RemoteCase c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top row: case number + status badge on opposite edges.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '#${c.caseNumber}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.mutedForeground,
                  ),
                ),
              ),
              CaseStatusBadge(status: c.status, statusLabel: c.statusLabel),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            c.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 24 / 16,
              color: AppColors.foreground,
            ),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 10),

          // Meta: opened date + lawyer.
          if (c.date.isNotEmpty)
            _metaRow(
              Icons.calendar_today_outlined,
              t('cases.openedLabel', vars: {'date': c.date}),
            ),
          if (c.lawyerName.isNotEmpty) ...[
            if (c.date.isNotEmpty) const SizedBox(height: 8),
            _metaRow(
              Icons.person_outline,
              t('cases.lawyerLabel', vars: {'name': c.lawyerName}),
            ),
          ],

          // Next-hearing gold banner (only when present).
          if (c.nextHearing.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.goldLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.schedule, size: 13, color: AppColors.gold),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      t(
                        'cases.nextHearingLabel',
                        vars: {'date': c.nextHearing},
                      ),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.cream,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _metaRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.mutedForeground),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.mutedForeground,
            ),
          ),
        ),
      ],
    );
  }
}
