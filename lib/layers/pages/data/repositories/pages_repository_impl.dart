import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:dsh_mobile/app/core/errors/failures.dart';
import 'package:dsh_mobile/app/localization/locale_controller.dart';
import 'package:dsh_mobile/app/supabase/supabase_config.dart';
import 'package:dsh_mobile/app/supabase/supabase_exceptions.dart';
import 'package:dsh_mobile/layers/pages/data/datasources/pages_remote_datasource.dart';
import 'package:dsh_mobile/layers/pages/data/models/page_section_model.dart';
import 'package:dsh_mobile/layers/pages/domain/entities/page_section.dart';
import 'package:dsh_mobile/layers/pages/domain/repositories/pages_repository.dart';

part 'pages_repository_impl.g.dart';

class PagesRepositoryImpl implements PagesRepository {
  final PagesRemoteDataSource _dataSource;
  final String _locale;

  PagesRepositoryImpl(this._dataSource, this._locale);

  @override
  Future<Either<Failure, List<PageSection>>> getSections(String page) async {
    try {
      final rows = await _dataSource.getSections(page);

      // Skip a section whose content will not parse rather than failing the
      // whole page. One malformed row written from the dashboard should cost
      // the reader that section, not the screen.
      final sections = <PageSection>[];
      for (final row in rows) {
        try {
          sections.add(
            PageSectionModel.fromRow(
                row, _locale, SupabaseConfig.defaultLocale),
          );
        } catch (_) {
          continue;
        }
      }

      return Right(sections);
    } catch (e) {
      return Left(SupabaseExceptions.toFailure(e));
    }
  }
}

@riverpod
PagesRepository pagesRepository(Ref ref) {
  // watch, not read: switching language rebuilds this so the copy refetches in
  // the new language along with the interface.
  final locale = ref.watch(localeControllerProvider).languageCode;

  return PagesRepositoryImpl(ref.read(pagesRemoteDataSourceProvider), locale);
}
