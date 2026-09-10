import 'package:dsh_mobile/app/supabase/lang_helper.dart';
import 'package:dsh_mobile/layers/home/domain/entities/home_section.dart';

/// Maps a `page_sections` row onto the domain entity.
///
/// Written by hand rather than with json_serializable: every text value is
/// JSONB keyed by language and has to go through `pickLang` with the active
/// locale, which a generated fromJson has no way to receive.
class HomeSectionModel {
  const HomeSectionModel._();

  static HomeSection? fromRow(
    Map<String, dynamic> row,
    String locale, [
    String defaultLocale = 'en',
  ]) {
    final kind = HomeSectionKind.fromDb(row['kind']?.toString());

    // A kind this build has no widget for. Dropped rather than rendered as a
    // blank gap — an older app meeting a newer dashboard shows one section
    // fewer, which is the least surprising outcome.
    if (kind == HomeSectionKind.unknown) return null;

    final content = row['content'] is Map
        ? Map<String, dynamic>.from(row['content'] as Map)
        : <String, dynamic>{};

    return HomeSection(
      id: row['id']?.toString() ?? '',
      kind: kind,
      position: (row['position'] as num?)?.toInt() ?? 0,
      title: pickLang(content['title'], locale, defaultLocale),
      // The database constrains this to 1–20, but a row written before that
      // constraint existed could still hold anything.
      limit: _clamp((content['limit'] as num?)?.toInt() ?? 4, 1, 20),
      picks: _picks(content),
      showViewAll: content['showViewAll'] == true,
      viewAllRoute: content['viewAllRoute']?.toString() ?? '',
      autoplaySeconds:
          _clamp((content['autoplaySeconds'] as num?)?.toInt() ?? 5, 2, 30),
      placeholder: pickLang(content['placeholder'], locale, defaultLocale),
      actions: _actions(content, locale, defaultLocale),
      body: pickLang(content['body'], locale, defaultLocale),
      buttons: _buttons(content, locale, defaultLocale),
      // Anything other than the one word 'manual' means the shared table.
      // Not `== 'stats'`: a row written before this setting existed has no
      // `source` key at all, and it must keep behaving exactly as it did.
      impactSource:
          content['source']?.toString() == 'manual' ? 'manual' : 'stats',
      figures: _figures(content, locale, defaultLocale),
    );
  }

  /// Hand-typed impact figures.
  ///
  /// Reads `figures`, NOT `items` — `quick_actions` and `cta` already use
  /// `items` on their own rows, and one shape per key is what keeps a
  /// half-filled section from being parsed as the wrong thing entirely.
  static List<HomeFigure> _figures(
    Map<String, dynamic> content,
    String locale,
    String defaultLocale,
  ) {
    final raw = content['figures'];
    if (raw is! List) return const [];

    return raw
        .whereType<Map>()
        .map((f) {
          final map = Map<String, dynamic>.from(f);
          return HomeFigure(
            value: map['value']?.toString().trim() ?? '',
            suffix: map['suffix']?.toString().trim() ?? '',
            label: pickLang(map['label'], locale, defaultLocale),
            icon: map['icon']?.toString() ?? '',
          );
        })
        // A figure with no number says nothing, and a number with no label
        // says less. Both are half-finished rows rather than content — the
        // same rule `impact_stats` is filtered by.
        .where((f) => f.value.isNotEmpty && f.label.trim().isNotEmpty)
        .toList();
  }

  static int _clamp(int value, int min, int max) =>
      value < min ? min : (value > max ? max : value);

  /// The editor's chosen slugs, in order.
  ///
  /// Blanks and duplicates are dropped here rather than in the widget: a
  /// duplicate would render the same card twice, and the dashboard has no
  /// business being the only thing standing between that and a reader.
  static List<String> _picks(Map<String, dynamic> content) {
    final raw = content['picks'];
    if (raw is! List) return const [];

    final seen = <String>{};
    final out = <String>[];
    for (final v in raw) {
      final slug = v?.toString().trim() ?? '';
      if (slug.isEmpty || !seen.add(slug)) continue;
      out.add(slug);
    }
    return out;
  }

  static List<QuickAction> _actions(
    Map<String, dynamic> content,
    String locale,
    String defaultLocale,
  ) {
    final raw = content['items'];
    if (raw is! List) return const [];

    return raw
        .whereType<Map>()
        .map((a) => QuickAction(
              icon: a['icon']?.toString() ?? '',
              label: pickLang(a['label'], locale, defaultLocale),
              route: a['route']?.toString() ?? '',
            ))
        // A tile with no destination is a dead tap. Better absent.
        .where((a) => a.label.trim().isNotEmpty && a.route.startsWith('/'))
        .toList();
  }

  static List<HomeCtaButton> _buttons(
    Map<String, dynamic> content,
    String locale,
    String defaultLocale,
  ) {
    final raw = content['buttons'];
    if (raw is! List) return const [];

    return raw
        .whereType<Map>()
        .map((b) => HomeCtaButton(
              label: pickLang(b['label'], locale, defaultLocale),
              route: b['route']?.toString() ?? '',
              style: b['style']?.toString() ?? 'secondary',
              icon: b['icon']?.toString() ?? '',
            ))
        .where((b) => b.label.trim().isNotEmpty && b.route.startsWith('/'))
        .toList();
  }
}
