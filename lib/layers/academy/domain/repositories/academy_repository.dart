import 'package:dartz/dartz.dart';

import 'package:dsh_mobile/app/core/errors/failures.dart';
import 'package:dsh_mobile/layers/academy/domain/entities/academy_program.dart';

abstract class AcademyRepository {
  /// Published programmes, newest first.
  ///
  /// An empty list is a valid answer — the module may be held on `mock` from
  /// the dashboard, or there may genuinely be nothing published yet. Both
  /// are the screen's empty state, not an error.
  Future<Either<Failure, List<AcademyProgram>>> getPrograms();

  /// One programme, or null when the slug matches nothing published.
  Future<Either<Failure, AcademyProgram?>> getProgramBySlug(String slug);
}
