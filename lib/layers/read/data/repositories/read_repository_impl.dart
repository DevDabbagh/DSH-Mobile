import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:dsh_mobile/app/core/errors/failures.dart';
import 'package:dsh_mobile/app/localization/locale_controller.dart';
import 'package:dsh_mobile/app/supabase/supabase_exceptions.dart';
import 'package:dsh_mobile/layers/read/data/datasources/read_remote_datasource.dart';
import 'package:dsh_mobile/layers/read/data/models/article_model.dart';
import 'package:dsh_mobile/layers/read/domain/entities/article.dart';
import 'package:dsh_mobile/layers/read/domain/repositories/read_repository.dart';

part 'read_repository_impl.g.dart';

class ReadRepositoryImpl implements ReadRepository {
  final ReadRemoteDataSource _dataSource;
  final String _locale;

  ReadRepositoryImpl(this._dataSource, this._locale);

  @override
  Future<Either<Failure, List<Article>>> getArticles() async {
    try {
      final rows = await _dataSource.getArticles();

      final articles = rows
          .map((r) => ArticleModel.fromRow(r, _locale))
          // A row an editor started and never titled. Dropped rather than
          // drawn as a card with a blank headline.
          .where((a) => !a.isEmpty)
          .toList();

      return Right(articles);
    } catch (e) {
      return Left(SupabaseExceptions.toFailure(e));
    }
  }

  @override
  Future<Either<Failure, Article?>> getArticleBySlug(String slug) async {
    try {
      // WHO IS ENTITLED TO A BODY, TODAY
      //
      // Free articles: everybody. Subscription articles: nobody, because this
      // app has no subscription to check. There is donation machinery and no
      // subscription product — `hasActiveSubscription` exists on the website
      // and has no counterpart here.
      //
      // So a paid article opens on the paywall card. That is the honest
      // outcome rather than a convenient one: the alternative is fetching the
      // body and covering it, which is the bug this whole path exists to
      // avoid.
      //
      // WHEN SUBSCRIPTIONS ARRIVE: resolve entitlement here — free OR an
      // active subscription for the signed-in user — and pass it through.
      // Nothing above this line needs to change, and nothing below it should
      // be asked to decide.
      final peek = await _dataSource.getArticleBySlug(slug, entitled: false);
      if (peek == null) return const Right(null);

      final access = ArticleAccess.fromDb((peek['access'] ?? '').toString());
      if (access.isPaid) {
        return Right(ArticleModel.fromRow(peek, _locale));
      }

      final full = await _dataSource.getArticleBySlug(slug, entitled: true);
      if (full == null) return const Right(null);

      return Right(ArticleModel.fromRow(full, _locale));
    } catch (e) {
      return Left(SupabaseExceptions.toFailure(e));
    }
  }
}

@riverpod
ReadRepository readRepository(Ref ref) {
  // watch, not read: switching language re-resolves the stored JSONB, and a
  // repository built with the old locale keeps serving the old strings.
  final locale = ref.watch(localeControllerProvider).languageCode;
  return ReadRepositoryImpl(ref.read(readRemoteDataSourceProvider), locale);
}
