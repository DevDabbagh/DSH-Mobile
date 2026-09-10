import 'package:dsh_mobile/app/supabase/lang_helper.dart';
import 'package:dsh_mobile/app/supabase/media_url.dart';
import 'package:dsh_mobile/layers/films/domain/entities/film.dart';

/// Turns a `films` row (with its joined festival, quote and screening rows)
/// into a [Film], resolving JSONB text to one language.
///
/// This is the Dart counterpart of `mapFilm()` in the website's `mappers.ts`.
/// Keep the two in step: a field added there and missed here is a field the
/// app silently drops.
class FilmModel {
  const FilmModel._();

  static Film fromRow(
    Map<String, dynamic> row,
    String locale,
    String defaultLocale,
  ) {
    String text(dynamic v) => pickLang(v, locale, defaultLocale);

    return Film(
      id: row['id'] as String,
      title: text(row['title']),
      slug: (row['slug'] as String?) ?? '',
      logline: text(row['logline']),
      synopsisShort: text(row['synopsis_short']),
      synopsisLong: text(row['synopsis_long']),
      editorialContext: text(row['editorial_context']),
      credits: FilmCredits(
        direction: (row['credit_direction'] as String?) ?? '',
        production: (row['credit_production'] as String?) ?? '',
        coProduction: (row['credit_co_production'] as String?) ?? '',
        year: (row['credit_year'] as String?) ?? '',
        duration: (row['credit_duration'] as String?) ?? '',
        form: FilmForm.fromDb(row['form'] as String?),
        format: FilmFormat.fromDb(row['format'] as String?),
        language: (row['credit_language'] as String?) ?? '',
        country: (row['credit_country'] as String?) ?? '',
      ),
      stage: FilmStage.fromDb(row['stage'] as String?),
      themes: stringList(row['themes']),
      trailerUrl: (row['trailer_url'] as String?) ?? '',
      // Site-relative paths are resolved here so the entity always carries
      // a URL a phone can fetch.
      thumbnailUrl: resolveMediaUrl(row['thumbnail_url']),
      posterUrl: resolveMediaUrl(row['poster_url']),
      detailsSliders: resolveMediaUrls(stringList(row['details_sliders'])),
      festivals: _list(row['film_festivals'])
          .map(
            (f) => FilmFestival(
              name: (f['name'] as String?) ?? '',
              year: (f['year'] as String?) ?? '',
              award: _orNull(f['award']),
              selection: _orNull(f['selection']),
            ),
          )
          .toList(),
      pressQuotes: _list(row['film_press_quotes'])
          .map(
            (q) => FilmPressQuote(
              source: (q['source'] as String?) ?? '',
              quote: (q['quote'] as String?) ?? '',
            ),
          )
          .toList(),
      screenings: _list(row['film_screenings'])
          .map(
            (s) => FilmScreening(
              event: (s['event'] as String?) ?? '',
              date: (s['date'] as String?) ?? '',
              location: (s['location'] as String?) ?? '',
              type: (s['type'] as String?) ?? 'festival',
            ),
          )
          .toList(),
      accessMode: (row['access_mode'] as String?) ?? 'public',
      isFeatured: (row['is_featured'] as bool?) ?? false,
    );
  }

  /// Joined rows arrive as `List<dynamic>`; a join with no matches is null.
  static List<Map<String, dynamic>> _list(dynamic value) {
    if (value is! List) return const [];
    return value.whereType<Map>().map(Map<String, dynamic>.from).toList();
  }

  /// Empty strings and nulls both mean "nothing here" for optional fields, and
  /// the UI hides a section on null — so collapse them to the same thing.
  static String? _orNull(dynamic value) {
    if (value is! String || value.trim().isEmpty) return null;
    return value;
  }
}
