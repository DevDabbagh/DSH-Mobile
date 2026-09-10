import 'package:equatable/equatable.dart';

/// One section of an editable page.
///
/// The dashboard's Pages editor writes rows into `page_sections`: a page is an
/// ordered list of these, each carrying its own content as JSONB. The same
/// rows drive the website, so copy written once appears on both surfaces.
///
/// `content` arrives here already resolved into the reader's language —
/// `PageSectionModel` walks the JSON and replaces every `{ en: …, ar: … }` map
/// with a plain string. The UI therefore never has to know that the content is
/// translated, and can never forget to call `pickLang`.
class PageSection extends Equatable {
  final String id;
  final String page;

  /// Which shape this is: `hero`, `intro`, `numbered_list`, `split_prose`,
  /// `pillars`, `people`, `stats`, `cards`, `quote`, `cta`.
  ///
  /// Deliberately a plain String rather than an enum. The dashboard can add a
  /// kind before the app has a widget for it, and an unknown kind must be
  /// skipped quietly — an enum would throw while parsing and take the whole
  /// screen down over one section the reader could have lived without.
  final String kind;

  final int position;
  final bool enabled;

  /// Language-resolved content. Values are `String`, `List`, or nested `Map`.
  final Map<String, dynamic> content;

  const PageSection({
    required this.id,
    required this.page,
    required this.kind,
    required this.position,
    required this.enabled,
    required this.content,
  });

  /// A single text value, or `''` when absent — callers hide on empty rather
  /// than null-check.
  String str(String key) {
    final v = content[key];
    return v is String ? v : '';
  }

  /// A repeatable list (team members, pillars, cards), or empty.
  List<Map<String, dynamic>> list(String key) {
    final v = content[key];
    if (v is! List) return const [];
    return v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  /// A list of translated paragraphs, already resolved to strings.
  List<String> paragraphs(String key) {
    final v = content[key];
    if (v is! List) return const [];
    return v.whereType<String>().where((s) => s.trim().isNotEmpty).toList();
  }

  @override
  List<Object?> get props => [id, page, kind, position, enabled, content];
}
