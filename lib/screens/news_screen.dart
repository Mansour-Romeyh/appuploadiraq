import 'package:flutter/material.dart';

import '../i18n/strings.dart';
import '../services/content_service.dart';
import '../theme/app_colors.dart';
import '../widgets/news_card.dart';
import '../widgets/remote_builder.dart';
import 'news_detail_screen.dart';

/// All-news list with staggered entrance animation, opened from home
/// (ported from app/(tabs)/news.tsx).
class NewsScreen extends StatelessWidget {
  const NewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: AppColors.navy,
            padding: EdgeInsets.only(
              top: topPadding + 16,
              left: 20,
              right: 20,
              bottom: 22,
            ),
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
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t('news.screenTitle'),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      t('news.screenSub'),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xA6FFFFFF),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: RemoteBuilder(
              load: ContentService.instance.news,
              onRetry: ContentService.instance.retryNews,
              emptyText: t('home.noNews'),
              builder: (context, newsItems) => ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                itemCount: newsItems.length,
                itemBuilder: (context, index) {
                  final item = newsItems[index];
                  return _AnimatedNewsCard(
                    index: index,
                    child: NewsCard(
                      item: item,
                      onPress: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => NewsDetailScreen(newsId: item.id),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Staggered fade + slide-up entrance per card.
class _AnimatedNewsCard extends StatefulWidget {
  final int index;
  final Widget child;

  const _AnimatedNewsCard({required this.index, required this.child});

  @override
  State<_AnimatedNewsCard> createState() => _AnimatedNewsCardState();
}

class _AnimatedNewsCardState extends State<_AnimatedNewsCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 90 * widget.index), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    return FadeTransition(
      opacity: curve,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.12),
          end: Offset.zero,
        ).animate(curve),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1).animate(curve),
          child: widget.child,
        ),
      ),
    );
  }
}
