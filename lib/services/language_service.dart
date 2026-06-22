import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../i18n/lang.dart';
import '../i18n/strings.dart' as strings;

/// App-wide language state persisted in SharedPreferences.
/// Mirrors law-firm-app/context/LanguageContext.tsx.
class LanguageService extends ChangeNotifier {
  LanguageService._();
  static final LanguageService instance = LanguageService._();

  static const _langKey = 'law_firm_lang_v1';
  static const Lang _defaultLang = Lang.ar;

  Lang _lang = _defaultLang;
  bool _isReady = false;

  Lang get lang => _lang;
  bool get isReady => _isReady;
  bool get isRTL => _lang.isRtl;
  TextDirection get dir => _lang.isRtl ? TextDirection.rtl : TextDirection.ltr;

  /// Kurdish ships with the NRT font; everything else uses Cairo.
  String get fontFamily => _lang == Lang.ku ? 'NRT' : 'Cairo';

  String t(String key, {Map<String, Object>? vars}) =>
      strings.translate(key, _lang, vars: vars);

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _lang = Lang.fromCode(prefs.getString(_langKey));
    } finally {
      _isReady = true;
      notifyListeners();
    }
  }

  Future<void> setLang(Lang next) async {
    _lang = next;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_langKey, next.code);
  }

  /// Test-only: restore the singleton to its pre-init state between tests.
  @visibleForTesting
  void resetForTest() {
    _lang = _defaultLang;
    _isReady = false;
  }
}
