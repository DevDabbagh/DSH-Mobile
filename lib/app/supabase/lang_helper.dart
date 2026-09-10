/// Resolving multilingual content coming from Supabase.
///
/// Text columns on the content tables are JSONB keyed by language code:
/// `{ "en": "…", "pt": "…", "ar": "…" }`. This mirrors `str()` in the
/// website's `lib/mappers.ts` so both surfaces fall back identically.
library;

/// Pick the best available string for [locale].
///
/// Order: the asked-for language, then the default, then any language that
/// actually has text. That last step matters — an editor who has filled in
/// only Portuguese should not leave the screen blank for an English reader.
///
/// Accepts a plain `String` too, so a column that was migrated from text to
/// JSONB keeps working either way.
String pickLang(
  dynamic value,
  String locale, [
  String defaultLocale = 'en',
]) {
  if (value is String) return value;

  if (value is Map) {
    final asked = value[locale];
    if (asked is String && asked.trim().isNotEmpty) return asked;

    final fallback = value[defaultLocale];
    if (fallback is String && fallback.trim().isNotEmpty) return fallback;

    for (final v in value.values) {
      if (v is String && v.trim().isNotEmpty) return v;
    }
  }

  return '';
}

/// A JSONB array column as a list of strings, dropping anything that isn't one.
List<String> stringList(dynamic value) {
  if (value is! List) return const [];
  return value.whereType<String>().where((s) => s.trim().isNotEmpty).toList();
}

/// The best available *list* for [locale], from a column keyed by language.
///
/// Same fallback order as [pickLang] — asked-for language, then the default,
/// then any language that has entries. Used by columns whose value per
/// language is an array rather than a string, such as the onboarding
/// headline's runs.
List<dynamic> pickLangList(
  dynamic value,
  String locale, [
  String defaultLocale = 'en',
]) {
  if (value is List) return value;
  if (value is! Map) return const [];

  final asked = value[locale];
  if (asked is List && asked.isNotEmpty) return asked;

  final fallback = value[defaultLocale];
  if (fallback is List && fallback.isNotEmpty) return fallback;

  for (final v in value.values) {
    if (v is List && v.isNotEmpty) return v;
  }

  return const [];
}
