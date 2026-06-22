import '../services/language_service.dart';
import 'localized.dart';

/// Resolve a piece of localized *content* (from the API) against the app's
/// current language. The mirror of the reference app's `tr(value, lang)`.
///
/// The whole widget tree rebuilds on language change (MaterialApp sits under a
/// `ListenableBuilder(LanguageService)`), so reading the singleton here is
/// enough — no per-widget listenable needed.
String tr(Localized value) => value.resolve(LanguageService.instance.lang);
