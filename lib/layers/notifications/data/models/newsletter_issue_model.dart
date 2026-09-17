import 'package:dsh_mobile/app/supabase/lang_helper.dart';
import 'package:dsh_mobile/app/supabase/media_url.dart';
import 'package:dsh_mobile/layers/notifications/domain/entities/newsletter_issue.dart';

/// Turns a `newsletter_archive()` row into a [NewsletterIssue].
class NewsletterIssueModel {
  const NewsletterIssueModel._();

  static NewsletterIssue fromRow(Map<String, dynamic> row, String locale) {
    return NewsletterIssue(
      id: (row['id'] ?? '').toString(),
      subject: pickLang(row['subject'], locale),
      preheader: pickLang(row['preheader'], locale),
      category: (row['category'] ?? '').toString(),
      // `newsletter_archive` filters out rows with a null sent_at, so this is
      // safe — but parsed defensively anyway, because a model that throws
      // takes the whole list down over one bad row.
      sentAt: DateTime.tryParse((row['sent_at'] ?? '').toString())?.toLocal() ??
          DateTime.fromMillisecondsSinceEpoch(0),
      body: _blocks(row['body'], locale),
    );
  }

  /// The block array.
  ///
  /// TWO SHAPES, AND WHY BOTH ARE HANDLED
  ///
  /// `body` is the same JSON the article editor writes, where each block's
  /// `content` is a plain string. But every other editable string in this
  /// project is JSONB keyed by language, and migration 043 made `subject` and
  /// `preheader` multilingual without saying what happens to the blocks. So
  /// `content` is read through [pickLang], which returns a `String` untouched
  /// and resolves a `Map` — whichever the composer turns out to write, this
  /// reads it.
  static List<NewsletterBlock> _blocks(dynamic value, String locale) {
    if (value is! List) return const [];

    final out = <NewsletterBlock>[];
    for (final raw in value) {
      if (raw is! Map) continue;

      final type = NewsletterBlockType.fromDb(raw['type']?.toString());
      if (type == NewsletterBlockType.unknown) continue;

      final content = pickLang(raw['content'], locale);

      // An image block whose URL is a site-relative path is meaningless on a
      // phone — the same problem `resolveMediaUrl` exists to solve for every
      // other image in the app.
      final resolved = type == NewsletterBlockType.image
          ? resolveMediaUrl(content)
          : content;

      // A block with nothing in it contributes a gap and a wondering reader.
      // A divider is the exception: emptiness is what it is.
      if (resolved.trim().isEmpty && type != NewsletterBlockType.divider) {
        continue;
      }

      final url = pickLang(raw['url'], locale).trim();

      // A button with no destination is dropped, matching the email renderer
      // ("No destination, no button"). It looks pressable and does nothing,
      // which reads as broken rather than as missing.
      if (type == NewsletterBlockType.cta && url.isEmpty) continue;

      final level = raw['level'];
      out.add(
        NewsletterBlock(
          type: type,
          content: resolved,
          caption: pickLang(raw['caption'], locale),
          credit: pickLang(raw['credit'], locale),
          url: url,
          level: level is int && level == 3 ? 3 : 2,
        ),
      );
    }
    return out;
  }
}
