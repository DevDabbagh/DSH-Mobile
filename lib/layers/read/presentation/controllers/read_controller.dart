import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:dsh_mobile/app/supabase/data_source_service.dart';
import 'package:dsh_mobile/layers/read/data/repositories/read_repository_impl.dart';
import 'package:dsh_mobile/layers/read/domain/entities/article.dart';

part 'read_controller.g.dart';

/// The Read listing.
///
/// keepAlive, like Films, Studio and Academy: fetched once and kept across
/// tab switches, so coming back does not re-query and re-render every card
/// from its placeholder.
@Riverpod(keepAlive: true)
class ReadArticles extends _$ReadArticles {
  @override
  Future<List<Article>> build() async {
    final result = await ref.watch(readRepositoryProvider).getArticles();
    return result.fold((failure) => throw failure, (articles) => articles);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    ref.read(dataSourceServiceProvider).invalidateCache();
    final result = await ref.read(readRepositoryProvider).getArticles();

    state = result.fold(
      (failure) => AsyncValue.error(failure, StackTrace.current),
      (articles) => AsyncValue.data(articles),
    );
  }
}

/// One article, by slug.
///
/// NOT served from the listing's cache, unlike Academy's equivalent. The
/// listing deliberately carries no bodies, so a cache hit here would hand the
/// details screen an article with nothing to read and no way to tell that
/// from a locked one.
@riverpod
Future<Article?> articleBySlug(Ref ref, String slug) async {
  final result = await ref.watch(readRepositoryProvider).getArticleBySlug(slug);
  return result.fold((failure) => throw failure, (article) => article);
}

/// What the reader has narrowed the listing to.
///
/// The facets are the website's — `ReadListing.tsx` filters on the tag and on
/// access — so both surfaces answer the same question the same way.
class ReadFilter extends Equatable {
  final String query;

  /// Matched against the PRETTIFIED tag, as the website does: it compares
  /// `prettyTag(a.tag)` to the chip label rather than the raw column, because
  /// the column holds `field_notes` and the chip says "Field notes".
  final String? tag;

  final ArticleAccess? access;

  const ReadFilter({this.query = '', this.tag, this.access});

  int get activeCount => (tag != null ? 1 : 0) + (access != null ? 1 : 0);

  bool get isActive => activeCount > 0 || query.trim().isNotEmpty;

  ReadFilter copyWith({
    String? query,
    String? tag,
    bool clearTag = false,
    ArticleAccess? access,
    bool clearAccess = false,
  }) =>
      ReadFilter(
        query: query ?? this.query,
        tag: clearTag ? null : (tag ?? this.tag),
        access: clearAccess ? null : (access ?? this.access),
      );

  List<Article> apply(List<Article> all) {
    final q = query.trim().toLowerCase();

    return all.where((a) {
      if (tag != null && prettyTag(a.tag) != tag) return false;
      if (access != null && a.access != access) return false;
      if (q.isEmpty) return true;

      return a.title.toLowerCase().contains(q) ||
          a.excerpt.toLowerCase().contains(q) ||
          a.author.name.toLowerCase().contains(q);
    }).toList();
  }

  @override
  List<Object?> get props => [query, tag, access];
}

/// `field_notes` → `Field notes`. The same function as `prettyTag` in
/// `ReadListing.tsx`, so a chip reads identically on both surfaces.
String prettyTag(String tag) {
  if (tag.trim().isEmpty) return '';
  final words = tag.replaceAll('_', ' ');
  return words[0].toUpperCase() + words.substring(1);
}

@riverpod
class ReadFilterController extends _$ReadFilterController {
  @override
  ReadFilter build() => const ReadFilter();

  void setQuery(String value) => state = state.copyWith(query: value);

  void setTag(String? value) => state =
      value == null ? state.copyWith(clearTag: true) : state.copyWith(tag: value);

  void setAccess(ArticleAccess? value) => state = value == null
      ? state.copyWith(clearAccess: true)
      : state.copyWith(access: value);

  void clear() => state = const ReadFilter();
}
