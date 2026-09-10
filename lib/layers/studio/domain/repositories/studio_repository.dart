import 'package:dartz/dartz.dart';

import 'package:dsh_mobile/app/core/errors/failures.dart';
import 'package:dsh_mobile/layers/studio/domain/entities/studio_project.dart';

abstract class StudioRepository {
  /// Published studio items, newest first — matching the website's
  /// `getStudioProjects()`.
  Future<Either<Failure, List<StudioProject>>> getProjects();

  /// One project by slug, with its episodes. `Right(null)` means no published
  /// project has that slug.
  Future<Either<Failure, StudioProject?>> getProjectBySlug(String slug);
}
