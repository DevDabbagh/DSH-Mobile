import 'package:dsh_mobile/app/supabase/lang_helper.dart';
import 'package:dsh_mobile/app/supabase/media_url.dart';
import 'package:dsh_mobile/layers/studio/domain/entities/studio_project.dart';

/// Dart counterpart of `mapStudioProject()` in the website's `mappers.ts`.
class StudioProjectModel {
  const StudioProjectModel._();

  static StudioProject fromRow(
    Map<String, dynamic> row,
    String locale,
    String defaultLocale,
  ) {
    String text(dynamic v) => pickLang(v, locale, defaultLocale);
    String? textOrNull(dynamic v) {
      final s = text(v);
      return s.trim().isEmpty ? null : s;
    }

    final episodes = _list(row['studio_episodes'])
        // A draft episode is one still being written. It must not appear even
        // when its parent project is published.
        .where((e) => ((e['status'] as String?) ?? 'published') != 'draft')
        .map((e) => _episode(e, text, textOrNull))
        .toList()
      // Supabase returns joined rows in no particular order; episodes are
      // listed in running order.
      ..sort((a, b) {
        final bySeason = (a.season ?? 1).compareTo(b.season ?? 1);
        if (bySeason != 0) return bySeason;
        return (a.number ?? 0).compareTo(b.number ?? 0);
      });

    return StudioProject(
      id: row['id'] as String,
      title: text(row['title']),
      slug: (row['slug'] as String?) ?? '',
      format: StudioFormat.fromDb(row['format'] as String?),
      oneLineDescription: text(row['description']),
      synopsisShort: text(row['synopsis_short']),
      synopsisLong: text(row['synopsis_long']),
      episodes: episodes,
      credits: StudioCredits(
        production: (row['credit_production'] as String?) ?? '',
        coProduction: (row['credit_co_production'] as String?) ?? '',
        hosts: _csv(row['credit_hosts_creators']),
        partners: _csv(row['credit_partners']),
        year: (row['credit_year'] as String?) ?? '',
        language: (row['credit_language'] as String?) ?? '',
        direction: _orNull(row['credit_direction']),
        duration: _orNull(row['credit_duration']),
        form: _orNull(row['credit_form']),
        formatLabel: _orNull(row['credit_format_label']),
        country: _orNull(row['credit_country']),
      ),
      stills: _nonEmptyStrings(row['stills']),
      status: StudioStatus.fromDb(row['studio_status'] as String?),
      editorialContext: text(row['editorial_context']),
      listenLinks: _list(row['studio_platform_links'])
          .map(
            (p) => StudioListenLink(
              platform: (p['platform'] as String?) ?? '',
              url: (p['url'] as String?) ?? '',
            ),
          )
          .toList(),
      relatedFilmIds: stringList(row['related_film_ids']),
      relatedArticleIds: stringList(row['related_article_ids']),
      thumbnailUrl: resolveMediaUrl(row['thumbnail_url']),
      coverUrl: resolveMediaUrl(row['cover_url']),
    );
  }

  static StudioEpisode _episode(
    Map<String, dynamic> e,
    String Function(dynamic) text,
    String? Function(dynamic) textOrNull,
  ) {
    return StudioEpisode(
      title: text(e['title']),
      description: text(e['description']),
      duration: _orNull(e['duration']),
      subtitle: textOrNull(e['subtitle']),
      number: _int(e['episode']),
      season: _int(e['season']),
      year: _orNull(e['year']),
      guest: textOrNull(e['guest']),
      imageUrl: _orNull(resolveMediaUrl(e['image_url'])),
      slug: _orNull(e['slug']),
      status: (e['status'] as String?) ?? 'published',
      videoUrl: _orNull(e['video_url']),
      videoProvider: _orNull(e['video_provider']),
      quotes: _quotes(e['quotes'], text),
      glossary: _entries(e['glossary'], text, textOrNull),
      glossaryIntro: textOrNull(e['glossary_intro']),
      glossaryNote: textOrNull(e['glossary_note']),
      recommendations: _entries(e['recommendations'], text, textOrNull),
      recommendationsIntro: textOrNull(e['recommendations_intro']),
      recommendationsNote: textOrNull(e['recommendations_note']),
      gallery: _nonEmptyStrings(e['gallery']),
      galleryIntro: textOrNull(e['gallery_intro']),
    );
  }

  /// Pull quotes may be plain strings or `{en, pt, ar}` maps depending on when
  /// they were written, so resolve each through the same language picker.
  static List<String>? _quotes(dynamic value, String Function(dynamic) text) {
    if (value is! List || value.isEmpty) return null;
    final out = value.map(text).where((q) => q.trim().isNotEmpty).toList();
    return out.isEmpty ? null : out;
  }

  static List<StudioEntry>? _entries(
    dynamic value,
    String Function(dynamic) text,
    String? Function(dynamic) textOrNull,
  ) {
    if (value is! List || value.isEmpty) return null;

    final out = value
        .whereType<Map>()
        .map(
          (raw) => StudioEntry(
            term: text(raw['term']),
            definition: text(raw['definition']),
            source: textOrNull(raw['source']),
            imageUrl: _orNull(resolveMediaUrl(raw['imageUrl'])),
          ),
        )
        // A card with no text in any language would render as an empty box.
        .where((e) => e.term.isNotEmpty || e.definition.isNotEmpty)
        .toList();

    return out.isEmpty ? null : out;
  }

  static List<String> _csv(dynamic value) {
    if (value is! String || value.trim().isEmpty) return const [];
    return value
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  /// Null rather than an empty list, because the sections that use these hide
  /// themselves on null.
  static List<String>? _nonEmptyStrings(dynamic value) {
    final list = resolveMediaUrls(stringList(value));
    return list.isEmpty ? null : list;
  }

  static List<Map<String, dynamic>> _list(dynamic value) {
    if (value is! List) return const [];
    return value.whereType<Map>().map(Map<String, dynamic>.from).toList();
  }

  static String? _orNull(dynamic value) {
    if (value is! String || value.trim().isEmpty) return null;
    return value;
  }

  /// Season and episode numbers may arrive as int or as a numeric string.
  static int? _int(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }
}
