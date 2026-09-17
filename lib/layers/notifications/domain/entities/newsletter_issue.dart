import 'package:equatable/equatable.dart';

/// One past issue of the newsletter.
///
/// Mirrors what `newsletter_archive()` returns — sent campaigns only, and only
/// the columns a reader may see. `recipient_count`, `failed_count`,
/// `sent_from` and `created_by` exist on the table and are deliberately not
/// here; see migration 044.
class NewsletterIssue extends Equatable {
  final String id;

  /// The subject line, already resolved to the reader's language.
  final String subject;

  /// The grey line an inbox shows after the subject. Often empty.
  final String preheader;

  final String category;
  final DateTime sentAt;

  /// The issue's content, as [NewsletterBlock]s.
  final List<NewsletterBlock> body;

  const NewsletterIssue({
    required this.id,
    required this.subject,
    required this.sentAt,
    this.preheader = '',
    this.category = '',
    this.body = const [],
  });

  /// The first paragraph, for the list row when there is no preheader — which
  /// there usually is not, because it is an optional field on a composer most
  /// editors will skip.
  String get teaser {
    if (preheader.trim().isNotEmpty) return preheader;

    for (final block in body) {
      if (block.type == NewsletterBlockType.text &&
          block.content.trim().isNotEmpty) {
        return block.content;
      }
    }
    return '';
  }

  @override
  List<Object?> get props => [id, subject, preheader, category, sentAt, body];
}

/// The block kinds the campaign composer produces.
///
/// `newsletter_campaigns.body` holds the same block JSON as `articles.body`
/// — migration 043 says so explicitly, and the reason is that the composer is
/// the article editor rather than a second one that works almost the same way.
/// So this enum matches `ArticleBlock["type"]` in the website's `types.ts`.
enum NewsletterBlockType {
  text,
  heading,
  image,
  quote,
  divider,

  /// A button. `content` is the label, `url` is where it goes.
  ///
  /// ONLY THE NEWSLETTER COMPOSER PRODUCES THIS
  ///
  /// `BlockEditor` takes an `allow` list and the articles form leaves `cta`
  /// out of it, which is why the website's article renderer has no case for
  /// one. The email renderer does, so an issue can carry a button — and this
  /// enum not knowing about it meant every CTA an editor wrote was dropped
  /// on the floor here while arriving fine in the inbox.
  cta,

  /// Raw HTML an editor pasted. Rendered as plain text with the tags stripped
  /// — see [NewsletterBlock]. Not dropped: the words in it are usually the
  /// point, and an issue with a hole in it reads as a bug.
  html,

  /// Anything this app has not been taught. Skipped rather than guessed at.
  unknown;

  static NewsletterBlockType fromDb(String? value) => switch (value) {
        'text' => NewsletterBlockType.text,
        'heading' => NewsletterBlockType.heading,
        'image' => NewsletterBlockType.image,
        'quote' => NewsletterBlockType.quote,
        'divider' => NewsletterBlockType.divider,
        'cta' => NewsletterBlockType.cta,
        'html' => NewsletterBlockType.html,
        _ => NewsletterBlockType.unknown,
      };
}

class NewsletterBlock extends Equatable {
  final NewsletterBlockType type;

  /// The text, or the image URL for an image block.
  final String content;

  final String caption;
  final String credit;

  /// Where a [NewsletterBlockType.cta] button goes. Empty for every other
  /// kind of block.
  final String url;

  /// 2 or 3 for a heading. Anything else is read as 2.
  final int level;

  const NewsletterBlock({
    required this.type,
    this.content = '',
    this.caption = '',
    this.credit = '',
    this.url = '',
    this.level = 2,
  });

  @override
  List<Object?> get props => [type, content, caption, credit, url, level];
}
