import 'package:dartz/dartz.dart';

import 'package:dsh_mobile/app/core/errors/failures.dart';
import 'package:dsh_mobile/layers/impact/domain/entities/impact_stat.dart';
import 'package:dsh_mobile/layers/impact/domain/entities/impact_story.dart';

abstract class ImpactRepository {
  /// The impact figures, newest first.
  ///
  /// Returns an empty list when the Impact module is held on `mock` from the
  /// dashboard — the rail then hides itself rather than showing invented
  /// numbers, which is the one thing an impact figure must never be.
  Future<Either<Failure, List<ImpactStat>>> getStats();

  /// Published impact stories, newest first.
  ///
  /// Same `mock` behaviour as [getStats], and for the same reason: an
  /// unfinished story is worse than no story.
  Future<Either<Failure, List<ImpactStory>>> getStories();
}
