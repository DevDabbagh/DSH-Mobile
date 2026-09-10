import 'package:dsh_mobile/app/supabase/lang_helper.dart';
import 'package:dsh_mobile/layers/pages/domain/entities/page_section.dart';

/// Turns a `page_sections` row into a [PageSection].
///
/// Not freezed, and deliberately so. `content` is free-form JSONB whose shape
/// changes per `kind` — a generated model would need one class per kind and a
/// discriminated union, and would then throw on any kind the dashboard added
/// before the app shipped a widget for it. The map stays a map.
///
/// What this class does do is resolve the language ONCE, on the way in.
/// Translated values are `{ "en": "…", "ar": "…" }` at any depth: a top-level
/// field, a field inside a repeater item, or a string in a paragraph list.
/// Walking the whole tree here means no widget can forget `pickLang`.
class PageSectionModel {
  static PageSection fromRow(
    Map<String, dynamic> row,
    String locale,
    String defaultLocale,
  ) {
    final raw = row['content'];
    final content = raw is Map
        ? Map<String, dynamic>.from(
            _resolve(Map<String, dynamic>.from(raw), locale, defaultLocale)
                as Map,
          )
        : <String, dynamic>{};

    return PageSection(
      id: row['id']?.toString() ?? '',
      page: row['page']?.toString() ?? '',
      kind: row['kind']?.toString() ?? '',
      position: (row['position'] as num?)?.toInt() ?? 0,
      enabled: row['enabled'] as bool? ?? true,
      content: content,
    );
  }

  /// Recursively replace every translation map with the right string.
  ///
  /// A map counts as a translation when every one of its values is a String
  /// and at least one key looks like a language code. That test matters: a
  /// repeater ITEM is also a map of strings (`{num: "01", title: {...}}`), and
  /// collapsing one of those into a single string would silently delete the
  /// section's content. Requiring a language-code key keeps them apart.
  static dynamic _resolve(dynamic node, String locale, String defaultLocale) {
    if (node is Map) {
      if (_looksTranslated(node)) {
        return pickLang(node, locale, defaultLocale);
      }
      return node.map(
        (k, v) => MapEntry(k.toString(), _resolve(v, locale, defaultLocale)),
      );
    }
    if (node is List) {
      return node.map((e) => _resolve(e, locale, defaultLocale)).toList();
    }
    return node;
  }

  /// Language codes we might see. Kept short on purpose — a longer list would
  /// start matching ordinary content keys and collapse real objects.
  static const _langKeys = {'en', 'ar', 'pt', 'es', 'fr', 'de'};

  static bool _looksTranslated(Map node) {
    if (node.isEmpty) return false;
    if (!node.values.every((v) => v is String)) return false;
    return node.keys.any((k) => _langKeys.contains(k.toString()));
  }
}
