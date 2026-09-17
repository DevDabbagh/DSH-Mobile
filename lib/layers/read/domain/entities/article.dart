import 'package:equatable/equatable.dart';

/// Who may read the body.
///
/// A word rather than a boolean, matching `articles.access` (migration 034):
/// `is_paid` reads fine today and badly the moment a third state appears.
enum ArticleAccess {
  free,
  subscription;

  static ArticleAccess fromDb(String? value) =>
      value == 'subscription' ? ArticleAccess.subscription : ArticleAccess.free;

  bool get isPaid => this == ArticleAccess.subscription;
}

/// One block of an article's body. Same shape as `ArticleBlock` in the
/// website's `types.ts`, minus `cta` — the articles form does not offer it.
enum ArticleBlockType {
  text,
  heading,
  image,
  quote,
  divider,
  html,
  unknown;

  static ArticleBlockType fromDb(String? value) => switch (value) {
        'text' => ArticleBlockType.text,
        'heading' => ArticleBlockType.heading,
        'image' => ArticleBlockType.image,
        'quote' => ArticleBlockType.quote,
        'divider' => ArticleBlockType.divider,
        'html' => ArticleBlockType.html,
        _ => ArticleBlockType.unknown,
      };
}

class ArticleBlock extends Equatable {
  final ArticleBlockType type;
  final String content;
  final String caption;
  final String credit;
  final int level;

  const ArticleBlock({
    required this.type,
    this.content = '',
    this.caption = '',
    this.credit = '',
    this.level = 2,
  });

  @override
  List<Object?> get props => [type, content, caption, credit, level];
}

class ArticleAuthor extends Equatable {
  final String name;
  final String avatarUrl;
  final String bio;

  const ArticleAuthor({this.name = '', this.avatarUrl = '', this.bio = ''});

  bool get isEmpty => name.trim().isEmpty;

  /// "TP" for Tiago Alexandre Pereira — first and last, not first two.
  ///
  /// `runes` rather than `[0]`: a name starting with an emoji or a character
  /// outside the basic plane is two code units, and taking the first one
  /// yields half a surrogate pair — which renders as the replacement glyph.
  String get initials {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (parts.isEmpty) return '';

    String first(String word) => String.fromCharCode(word.runes.first);

    if (parts.length == 1) return first(parts.first).toUpperCase();
    return (first(parts.first) + first(parts.last)).toUpperCase();
  }

  @override
  List<Object?> get props => [name, avatarUrl, bio];
}

/// A piece of writing in the Read section.
///
/// Mirrors `Article` in the website's `lib/types.ts` field for field, so the
/// two surfaces cannot drift into showing different things from one row.
class Article extends Equatable {
  final String id;
  final String slug;
  final String title;
  final String excerpt;
  final DateTime date;

  /// What KIND of writing it is — the coloured chip. "Investigation",
  /// "Essays", "Opinion"…
  final String tag;

  /// Which PART of DSH it belongs to — the plain word beside the date. A
  /// different question from [tag], which is why migration 034 added a second
  /// column rather than overloading the first.
  final String section;

  final String mainImageUrl;
  final String mainImageCaption;
  final String mainImageCredit;

  final ArticleAuthor author;
  final List<ArticleBlock> body;

  final ArticleAccess access;
  final bool featured;

  /// 0 means "not measured" — the page then shows no reading time rather than
  /// claiming an article takes no time to read.
  final int readMinutes;

  final List<String> relatedArticleIds;

  const Article({
    required this.id,
    required this.slug,
    required this.title,
    required this.date,
    this.excerpt = '',
    this.tag = '',
    this.section = '',
    this.mainImageUrl = '',
    this.mainImageCaption = '',
    this.mainImageCredit = '',
    this.author = const ArticleAuthor(),
    this.body = const [],
    this.access = ArticleAccess.free,
    this.featured = false,
    this.readMinutes = 0,
    this.relatedArticleIds = const [],
  });

  /// A row an editor created but never filled in. The tab drops these rather
  /// than rendering a card with no title, which reads as a broken app.
  bool get isEmpty => title.trim().isEmpty;

  /// THE BODY IS ABSENT, NOT MERELY UNREAD
  ///
  /// For a subscription article the app never receives `body` at all — the
  /// query does not select it. This is the difference between a paywall and a
  /// curtain: hiding text the client already holds is not withholding it, and
  /// migration 034 says so in capitals.
  bool get isLocked => access.isPaid && body.isEmpty;

  @override
  List<Object?> get props => [id, slug, title, date, tag, access, featured];
}
