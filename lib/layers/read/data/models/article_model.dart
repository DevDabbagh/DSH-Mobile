import 'package:dsh_mobile/app/supabase/lang_helper.dart';
import 'package:dsh_mobile/app/supabase/media_url.dart';
import 'package:dsh_mobile/layers/read/domain/entities/article.dart';

/// Turns an `articles` row into an [Article].
class ArticleModel {
  const ArticleModel._();

  static Article fromRow(Map<String, dynamic> row, String locale) {
    final author = row['author'];

    return Article(
      id: (row['id'] ?? '').toString(),
      slug: (row['slug'] ?? '').toString(),
      title: pickLang(row['title'], locale),
      excerpt: pickLang(row['excerpt'], locale),
      date: DateTime.tryParse((row['date'] ?? '').toString())?.toLocal() ??
          DateTime.now(),
      tag: (row['tag'] ?? '').toString(),
      section: (row['section'] ?? '').toString(),
      mainImageUrl: resolveMediaUrl(row['main_image']),
      mainImageCaption: (row['main_image_caption'] ?? '').toString(),
      mainImageCredit: (row['main_image_credit'] ?? '').toString(),
      author: _author(author, locale),
      // Absent on the listing select, which is deliberate — see the data
      // source. An empty body on a paid article is what [Article.isLocked]
      // reads.
      body: _blocks(row['body'], locale),
      access: ArticleAccess.fromDb((row['access'] ?? '').toString()),
      featured: row['featured'] == true,
      readMinutes: _int(row['read_minutes']),
      relatedArticleIds: stringList(row['related_article_ids']),
    );
  }

  static ArticleAuthor _author(dynamic value, String locale) {
    if (value is! Map) return const ArticleAuthor();

    return ArticleAuthor(
      name: pickLang(value['name'], locale),
      avatarUrl: resolveMediaUrl(value['avatar']),
      bio: pickLang(value['bio'], locale),
    );
  }

  static int _int(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse((value ?? '').toString()) ?? 0;
  }

  static List<ArticleBlock> _blocks(dynamic value, String locale) {
    if (value is! List) return const [];

    final out = <ArticleBlock>[];
    for (final raw in value) {
      if (raw is! Map) continue;

      final type = ArticleBlockType.fromDb(raw['type']?.toString());
      if (type == ArticleBlockType.unknown) continue;

      final content = pickLang(raw['content'], locale);

      // A site-relative path is meaningless on a phone — the same problem
      // `resolveMediaUrl` exists to solve for every other image in the app.
      final resolved = type == ArticleBlockType.image
          ? resolveMediaUrl(content)
          : content;

      if (resolved.trim().isEmpty && type != ArticleBlockType.divider) {
        continue;
      }

      final level = raw['level'];
      out.add(
        ArticleBlock(
          type: type,
          content: resolved,
          caption: pickLang(raw['caption'], locale),
          credit: pickLang(raw['credit'], locale),
          level: level is int && level == 3 ? 3 : 2,
        ),
      );
    }
    return out;
  }
}
