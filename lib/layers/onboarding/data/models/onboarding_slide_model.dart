import 'package:dsh_mobile/app/supabase/lang_helper.dart';
import 'package:dsh_mobile/app/supabase/media_url.dart';
import 'package:dsh_mobile/layers/onboarding/domain/entities/onboarding_slide.dart';

/// Maps a `mobile_onboarding_slides` row onto the domain entity.
///
/// Written by hand rather than with json_serializable: every text column is
/// JSONB that has to go through the language helpers with the active locale,
/// which a generated fromJson has no way to receive.
class OnboardingSlideModel {
  const OnboardingSlideModel._();

  static OnboardingSlide fromRow(
    Map<String, dynamic> row,
    String locale, [
    String defaultLocale = 'en',
  ]) {
    return OnboardingSlide(
      id: row['id']?.toString() ?? '',
      sortOrder: (row['sort_order'] as num?)?.toInt() ?? 0,
      images: resolveMediaUrls(stringList(row['images'])),
      titleSegments: _segments(row, locale, defaultLocale),
      description: pickLang(row['description'], locale, defaultLocale),
      showLogo: row['show_logo'] == true,
    );
  }

  /// The headline runs, or the old two-field shape rebuilt as runs.
  ///
  /// Rows written before `title_segments` existed still have only `title` and
  /// `title_highlight`, and a build of the app newer than the dashboard would
  /// otherwise show them a blank headline.
  static List<TitleSegment> _segments(
    Map<String, dynamic> row,
    String locale,
    String defaultLocale,
  ) {
    final raw = pickLangList(row['title_segments'], locale, defaultLocale);

    final parsed = raw
        .whereType<Map>()
        .map(
          (m) => (
            text: (m['text'] as String?) ?? '',
            highlight: m['highlight'] == true,
          ),
        )
        .where((s) => s.text.isNotEmpty)
        .toList();

    if (parsed.isNotEmpty) return parsed;

    // ── Fallback: title + trailing highlight ──
    final title = pickLang(row['title'], locale, defaultLocale);
    final highlight = pickLang(row['title_highlight'], locale, defaultLocale);

    return [
      if (title.isNotEmpty)
        (text: highlight.isEmpty ? title : '$title ', highlight: false),
      if (highlight.isNotEmpty) (text: highlight, highlight: true),
    ];
  }
}
