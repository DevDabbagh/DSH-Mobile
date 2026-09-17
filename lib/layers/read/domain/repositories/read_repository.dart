import 'package:dartz/dartz.dart';

import 'package:dsh_mobile/app/core/errors/failures.dart';
import 'package:dsh_mobile/layers/read/domain/entities/article.dart';

abstract class ReadRepository {
  /// Every published article, newest first. Bodies excluded — see
  /// `ReadRemoteDataSource`.
  Future<Either<Failure, List<Article>>> getArticles();

  /// One article. The body comes back only when the reader is entitled to it;
  /// otherwise [Article.isLocked] is true and the screen shows the paywall.
  Future<Either<Failure, Article?>> getArticleBySlug(String slug);
}
