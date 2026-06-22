/// Supported UI languages. `ku` = Sorani Kurdish (Arabic script, RTL).
enum Lang {
  ar('ar'),
  en('en'),
  ku('ku');

  const Lang(this.code);

  /// Two-letter language code persisted in storage and sent to the backend.
  final String code;

  /// `ar` and `ku` are right-to-left; English is the only LTR option.
  bool get isRtl => this == Lang.ar || this == Lang.ku;

  /// Parse a stored code; unknown/null falls back to Arabic (the default).
  static Lang fromCode(String? code) =>
      Lang.values.firstWhere((l) => l.code == code, orElse: () => Lang.ar);
}

/// Display order for the language switcher (matches the RN `LANGS` order).
const List<Lang> langOrder = [Lang.ar, Lang.en, Lang.ku];

/// Switcher labels: `label` is the English name, `native` the autonym.
typedef LangMeta = ({String label, String native});

const Map<Lang, LangMeta> langMeta = {
  Lang.ar: (label: 'Arabic', native: 'العربية'),
  Lang.en: (label: 'English', native: 'English'),
  Lang.ku: (label: 'Kurdish', native: 'کوردی'),
};
