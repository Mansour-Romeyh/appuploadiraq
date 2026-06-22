import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/laws.dart';
import '../i18n/strings.dart';
import '../models/law.dart';
import '../theme/app_colors.dart';

/// Laws library tab: law list → chapter accordion → articles,
/// with global full-text search (ported from app/(tabs)/laws.tsx).
class LawsScreen extends StatefulWidget {
  const LawsScreen({super.key});

  @override
  State<LawsScreen> createState() => _LawsScreenState();
}

class _LawsScreenState extends State<LawsScreen> {
  final TextEditingController _queryController = TextEditingController();
  LawDocument? _selectedLaw;
  final Set<String> _expanded = {};

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  bool get _isSearching => _queryController.text.trim().isNotEmpty;

  List<FlatArticle> get _searchResults {
    final q = _queryController.text.trim().toLowerCase();
    if (q.isEmpty) return const [];
    return allArticles
        .where(
          (a) =>
              a.text.toLowerCase().contains(q) ||
              a.number.toString().contains(q) ||
              a.chapterTitle.toLowerCase().contains(q) ||
              a.lawTitle.toLowerCase().contains(q),
        )
        .toList();
  }

  void _toggleChapter(String id) {
    HapticFeedback.lightImpact();
    setState(() {
      if (!_expanded.add(id)) _expanded.remove(id);
    });
  }

  void _openLaw(LawDocument law) {
    HapticFeedback.mediumImpact();
    setState(() {
      _expanded.clear();
      _selectedLaw = law;
    });
  }

  void _goBack() {
    setState(() {
      _selectedLaw = null;
      _expanded.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final selectedLaw = _selectedLaw;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Container(
          padding: EdgeInsets.only(
            top: topPadding + 12,
            left: 20,
            right: 20,
            bottom: 14,
          ),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0x14FFFFFF))),
          ),
          child: Row(
            children: [
              if (selectedLaw != null)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _goBack,
                  child: const SizedBox(
                    width: 42,
                    height: 42,
                    child: Icon(
                      Icons.arrow_forward,
                      size: 20,
                      color: AppColors.gold,
                    ),
                  ),
                )
              else
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.gold.withAlpha(0x22),
                    border: Border.all(color: AppColors.gold.withAlpha(0x66)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset(
                    'assets/images/law-logo.jpg',
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedLaw?.title ?? t('laws.screenTitle'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      selectedLaw?.subtitle ??
                          t(
                            'laws.headerSubList',
                            vars: {
                              'count': '${allLaws.length}',
                              'articles': '${allArticles.length}',
                            },
                          ),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.gold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Search bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0x14FFFFFF))),
          ),
          child: SizedBox(
            height: 42,
            child: TextField(
              controller: _queryController,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(fontSize: 14, color: Colors.white),
              decoration: InputDecoration(
                hintText: t('laws.searchPlaceholder'),
                hintStyle: const TextStyle(color: Color(0x59FFFFFF)),
                prefixIcon: const Icon(
                  Icons.search,
                  size: 16,
                  color: Color(0x66FFFFFF),
                ),
                suffixIcon: _queryController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _queryController.clear();
                          setState(() {});
                        },
                        icon: const Icon(
                          Icons.cancel_outlined,
                          size: 16,
                          color: Color(0x66FFFFFF),
                        ),
                      )
                    : null,
                filled: true,
                fillColor: const Color(0x14FFFFFF),
                contentPadding: EdgeInsets.zero,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: Color(0x1FFFFFFF)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: AppColors.gold),
                ),
              ),
            ),
          ),
        ),

        // Content
        Expanded(
          child: _isSearching
              ? _buildSearchResults()
              : selectedLaw != null
              ? _buildChapters(selectedLaw)
              : _buildLawList(),
        ),
      ],
    );
  }

  Widget _buildSearchResults() {
    final results = _searchResults;
    if (results.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🔍', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 12),
          Text(
            t('laws.noResults', vars: {'query': _queryController.text}),
            style: const TextStyle(fontSize: 14, color: Color(0x73FFFFFF)),
          ),
        ],
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 100),
      itemCount: results.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              t('laws.resultsCount', vars: {'count': '${results.length}'}),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.gold,
              ),
            ),
          );
        }
        final item = results[index - 1];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 4),
                child: Text(
                  item.lawTitle,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gold,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 4),
                child: Text(
                  item.chapterTitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0x73FFFFFF),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              _buildArticle(Article(number: item.number, text: item.text)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLawList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 100),
      itemCount: allLaws.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.gold.withAlpha(0x14),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.gold.withAlpha(0x33)),
            ),
            child: Row(
              children: [
                const Text('📚', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t('laws.libraryTitle'),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        t(
                          'laws.librarySummary',
                          vars: {
                            'count': '${allLaws.length}',
                            'articles': '${allArticles.length}',
                          },
                        ),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0x8CFFFFFF),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
        final law = allLaws[index - 1];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GestureDetector(
            onTap: () => _openLaw(law),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0x0DFFFFFF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0x1AFFFFFF)),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 36,
                    child: Text(
                      law.icon,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 26),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          law.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          law.subtitle,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.gold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.gold.withAlpha(0x22),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${law.chapters.length} ${t('laws.chapters')}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.gold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0x14FFFFFF),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${law.totalArticles} ${t('laws.articles')}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0x8CFFFFFF),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_left,
                    size: 18,
                    color: Color(0x4DFFFFFF),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildChapters(LawDocument law) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 100),
      itemCount: law.chapters.length,
      itemBuilder: (context, index) {
        final chapter = law.chapters[index];
        final isOpen = _expanded.contains(chapter.id);
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Column(
            children: [
              GestureDetector(
                onTap: () => _toggleChapter(chapter.id),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isOpen
                        ? AppColors.gold.withAlpha(0x1A)
                        : const Color(0x0DFFFFFF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isOpen
                          ? AppColors.gold.withAlpha(0x55)
                          : const Color(0x14FFFFFF),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isOpen
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        size: 16,
                        color: isOpen
                            ? AppColors.gold
                            : const Color(0x73FFFFFF),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          chapter.title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isOpen ? AppColors.gold : Colors.white,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withAlpha(0x22),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${chapter.articles.length}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.gold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (isOpen)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  child: Column(
                    children: [
                      for (final article in chapter.articles)
                        _buildArticle(article),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildArticle(Article article) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0x0DFFFFFF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x26C9A84C)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.gold.withAlpha(0x22),
              border: Border.all(color: AppColors.gold.withAlpha(0x55)),
            ),
            child: Center(
              child: Text(
                '${article.number}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              article.text,
              style: const TextStyle(
                fontSize: 13,
                height: 22 / 13,
                color: Color(0xE0FFFFFF),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
