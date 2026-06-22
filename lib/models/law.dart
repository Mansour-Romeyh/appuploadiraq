class Article {
  final int number;
  final String text;

  const Article({required this.number, required this.text});
}

class Chapter {
  final String id;
  final String title;
  final List<Article> articles;

  const Chapter({
    required this.id,
    required this.title,
    required this.articles,
  });
}

class LawDocument {
  final String id;
  final String title;
  final String subtitle;
  final String year;
  final String icon;
  final List<Chapter> chapters;

  const LawDocument({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.year,
    required this.icon,
    required this.chapters,
  });

  int get totalArticles =>
      chapters.fold(0, (sum, ch) => sum + ch.articles.length);
}

class FlatArticle {
  final int number;
  final String text;
  final String chapterTitle;
  final String chapterId;
  final String lawId;
  final String lawTitle;

  const FlatArticle({
    required this.number,
    required this.text,
    required this.chapterTitle,
    required this.chapterId,
    required this.lawId,
    required this.lawTitle,
  });
}
