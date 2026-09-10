import 'package:dartz/dartz.dart';

import 'package:dsh_mobile/app/core/errors/failures.dart';
import 'package:dsh_mobile/layers/pages/domain/entities/page_section.dart';

abstract class PagesRepository {
  /// Enabled sections for [page], in the order the editor arranged them.
  ///
  /// An empty list is a legitimate answer, not an error: a page whose sections
  /// have all been disabled should show its empty state, not a failure.
  Future<Either<Failure, List<PageSection>>> getSections(String page);
}
