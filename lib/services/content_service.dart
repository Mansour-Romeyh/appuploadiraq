import '../models/lawyer.dart';
import '../models/legal_service.dart';
import '../models/news_item.dart';
import 'api_service.dart';

/// Backend-only content stores (mirrors the reference app's `useRemoteContent`).
/// The app renders exactly what the ERP doctypes — Legal Service / Legal News /
/// Legal Team Member — return; there is no bundled dummy fallback.
///
/// Each feed's fetch is memoized so a single request per app session is shared
/// across every screen (home preview, list, detail). A failed fetch is *not*
/// cached: the future rejects and the memo is cleared so the next consumer (or a
/// Retry tap) starts a fresh request.
class ContentService {
  ContentService._();
  static final ContentService instance = ContentService._();

  Future<List<LegalService>>? _services;
  Future<List<NewsItem>>? _news;
  Future<List<Lawyer>>? _team;

  Future<List<LegalService>> services() => _services ??= _guard(
    ApiService.instance.getServices(),
    () => _services = null,
  );
  Future<List<NewsItem>> news() =>
      _news ??= _guard(ApiService.instance.getNews(), () => _news = null);
  Future<List<Lawyer>> team() =>
      _team ??= _guard(ApiService.instance.getTeam(), () => _team = null);

  /// Drop the cached future so the next call re-fetches (used by Retry).
  void retryServices() => _services = null;
  void retryNews() => _news = null;
  void retryTeam() => _team = null;

  /// Clear the memo if the request fails, then rethrow so the awaiting
  /// RemoteBuilder shows its error state.
  static Future<T> _guard<T>(Future<T> future, void Function() clear) {
    return future.catchError((Object e) {
      clear();
      throw e;
    });
  }
}
