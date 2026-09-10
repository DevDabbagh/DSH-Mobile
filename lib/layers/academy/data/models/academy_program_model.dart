import 'package:dsh_mobile/app/supabase/lang_helper.dart';
import 'package:dsh_mobile/app/supabase/media_url.dart';
import 'package:dsh_mobile/layers/academy/domain/entities/academy_program.dart';

/// Maps an `academy_programs` row onto the domain entity.
///
/// Written by hand rather than with json_serializable: every text column is
/// JSONB that has to go through the language helpers with the active locale,
/// which a generated fromJson has no way to receive.
///
/// Mirrors `mapAcademyProgram` in the website's `lib/mappers.ts`, including
/// its fallbacks — the two surfaces read the same rows, and a row that shows
/// a curriculum on the site and a blank list in the app is a bug that only
/// turns up when someone compares them side by side.
class AcademyProgramModel {
  const AcademyProgramModel._();

  static AcademyProgram fromRow(
    Map<String, dynamic> row,
    String locale, [
    String defaultLocale = 'en',
  ]) {
    return AcademyProgram(
      id: row['id']?.toString() ?? '',
      slug: row['slug']?.toString() ?? '',
      title: pickLang(row['title'], locale, defaultLocale),
      description: pickLang(row['description'], locale, defaultLocale),
      type: AcademyType.fromDb(row['type']?.toString()),
      format: AcademyFormat.fromDb(row['format']?.toString()),
      whoLeads: pickLang(row['who_leads'], locale, defaultLocale),
      whoItsFor: pickLang(row['who_its_for'], locale, defaultLocale),
      scholarshipNote: pickLang(row['scholarship_note'], locale, defaultLocale),
      howToJoin: pickLang(row['how_to_join'], locale, defaultLocale),
      duration: row['duration']?.toString() ?? '',
      dates: row['dates']?.toString() ?? '',
      year: row['year']?.toString() ?? '',
      isFree: row['is_free'] != false,
      price: (row['price'] as num?)?.toDouble(),
      currency: (row['currency']?.toString().trim().isNotEmpty ?? false)
          ? row['currency'].toString()
          : 'EUR',
      // Thumbnails on older rows are site-relative `/images/…` paths, which
      // mean nothing on a phone. Same fix as films and studio.
      thumbnailUrl: resolveMediaUrl(row['thumbnail_url']),
      lessons: _lessons(row, locale, defaultLocale),
      resources: _resources(row),
      testimonials: _testimonials(row, locale, defaultLocale),
      partnerships: _partnerships(row, locale, defaultLocale),
      certification: _certification(row, locale, defaultLocale),
      relatedFilmIds: stringList(row['related_film_ids']),
      relatedStudioIds: stringList(row['related_studio_ids']),
      enrolledCount: (row['enrolled_count'] as num?)?.toInt() ?? 0,
    );
  }

  /// The curriculum.
  ///
  /// Rows written before migration 031 have no `lessons`, so their
  /// `objectives` are read as unlocked, untimed lessons — the screen must not
  /// go blank for a programme nobody has re-saved yet.
  static List<AcademyLesson> _lessons(
    Map<String, dynamic> row,
    String locale,
    String defaultLocale,
  ) {
    final raw = row['lessons'];

    if (raw is List && raw.isNotEmpty) {
      return raw
          .whereType<Map>()
          .map((l) {
            return AcademyLesson(
              title: pickLang(l['title'], locale, defaultLocale),
              duration: l['duration'] is String ? l['duration'] as String : '',
              locked: l['locked'] == true,
              videoUrl: l['videoUrl'] is String ? l['videoUrl'] as String : '',
            );
          })
          .where((l) => l.title.trim().isNotEmpty)
          .toList();
    }

    return stringList(row['objectives'])
        .map((title) => AcademyLesson(title: title))
        .toList();
  }

  static List<AcademyResource> _resources(Map<String, dynamic> row) {
    final raw = row['academy_resources'];
    if (raw is! List) return const [];

    final items = raw.whereType<Map>().toList()
      ..sort((a, b) {
        final pa = (a['position'] as num?)?.toInt() ?? 0;
        final pb = (b['position'] as num?)?.toInt() ?? 0;
        return pa.compareTo(pb);
      });

    return items
        .map((r) => AcademyResource(
              id: r['id']?.toString() ?? '',
              // Not multilingual in the schema — a plain TEXT column.
              title: r['title']?.toString() ?? '',
              type: r['type']?.toString() ?? 'link',
              url: r['url']?.toString() ?? '',
              sizeLabel: r['size_label']?.toString() ?? '',
              locked: r['locked'] == true,
            ))
        .where((r) => r.title.trim().isNotEmpty && r.url.trim().isNotEmpty)
        .toList();
  }

  static List<AcademyTestimonial> _testimonials(
    Map<String, dynamic> row,
    String locale,
    String defaultLocale,
  ) {
    final raw = row['testimonials'];
    if (raw is! List) return const [];

    return raw
        .whereType<Map>()
        .map((t) => AcademyTestimonial(
              quote: pickLang(t['quote'], locale, defaultLocale),
              // The author's name is a name, not copy — the same in every
              // language, so it is stored as a plain string. pickLang still
              // handles it, in case an editor typed it as an object.
              author: pickLang(t['author'], locale, defaultLocale),
            ))
        .where((t) => t.quote.trim().isNotEmpty)
        .toList();
  }

  static List<AcademyPartnership> _partnerships(
    Map<String, dynamic> row,
    String locale,
    String defaultLocale,
  ) {
    final raw = row['partnerships'];
    if (raw is! List) return const [];

    return raw
        .whereType<Map>()
        .map((p) => AcademyPartnership(
              label: pickLang(p['label'], locale, defaultLocale),
              title: pickLang(p['title'], locale, defaultLocale),
              body: pickLang(p['body'], locale, defaultLocale),
            ))
        .where((p) => p.title.trim().isNotEmpty || p.body.trim().isNotEmpty)
        .toList();
  }

  static AcademyCertification _certification(
    Map<String, dynamic> row,
    String locale,
    String defaultLocale,
  ) {
    final raw = row['certification'];
    if (raw is! Map) return const AcademyCertification();

    return AcademyCertification(
      label: pickLang(raw['label'], locale, defaultLocale),
      value: pickLang(raw['value'], locale, defaultLocale),
    );
  }
}
