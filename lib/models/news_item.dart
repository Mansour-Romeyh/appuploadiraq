import '../i18n/localized.dart';

/// A Legal News article, as returned by `law_firm.api.mobile.get_news`.
///
/// `category` is a stable (non-localized) Arabic key used only for the accent
/// color lookup; `categoryLabel` is the localized text shown on the badge. The
/// other text fields carry `{ar,en,ku}` and resolve with `tr(...)`.
class NewsItem {
  final String id;
  final String category;
  final Localized categoryLabel;
  final Localized title;
  final Localized summary;
  final Localized content;
  final String date;
  final String imageUrl;

  const NewsItem({
    required this.id,
    required this.category,
    required this.categoryLabel,
    required this.title,
    required this.summary,
    required this.content,
    required this.date,
    required this.imageUrl,
  });

  factory NewsItem.fromJson(Map<String, dynamic> j) => NewsItem(
    id: j['id']?.toString() ?? '',
    category: j['category'] as String? ?? '',
    categoryLabel: Localized.fromJson(j['categoryLabel']),
    title: Localized.fromJson(j['title']),
    summary: Localized.fromJson(j['summary']),
    content: Localized.fromJson(j['content']),
    date: j['date'] as String? ?? '',
    imageUrl: j['imageUrl'] as String? ?? '',
  );
}
