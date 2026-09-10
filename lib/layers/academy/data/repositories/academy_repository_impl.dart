import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:dsh_mobile/app/core/errors/failures.dart';
import 'package:dsh_mobile/app/localization/locale_controller.dart';
import 'package:dsh_mobile/app/supabase/data_source_service.dart';
import 'package:dsh_mobile/app/supabase/supabase_config.dart';
import 'package:dsh_mobile/app/supabase/supabase_exceptions.dart';
import 'package:dsh_mobile/layers/academy/data/datasources/academy_remote_datasource.dart';
import 'package:dsh_mobile/layers/academy/data/models/academy_program_model.dart';
import 'package:dsh_mobile/layers/academy/domain/entities/academy_program.dart';
import 'package:dsh_mobile/layers/academy/domain/repositories/academy_repository.dart';

part 'academy_repository_impl.g.dart';

class AcademyRepositoryImpl implements AcademyRepository {
  final AcademyRemoteDataSource _dataSource;
  final DataSourceService _dataSources;
  final String _locale;

  AcademyRepositoryImpl(this._dataSource, this._dataSources, this._locale);

  @override
  Future<Either<Failure, List<AcademyProgram>>> getPrograms() async {
    try {
      // The dashboard can hold the Academy back while it is being filled in.
      // The website substitutes its bundled placeholders here; the app
      // returns nothing and lets the screen show its empty state, because
      // placeholder courses inside a shipped binary read as real ones.
      if (!await _dataSources.isLive(ContentModule.academy)) {
        return const Right([]);
      }

      final rows = await _dataSource.getPrograms();

      return Right(
        rows.map(_toEntity).where((p) => !p.isEmpty).toList(),
      );
    } catch (e) {
      return Left(SupabaseExceptions.toFailure(e));
    }
  }

  @override
  Future<Either<Failure, AcademyProgram?>> getProgramBySlug(String slug) async {
    try {
      if (!await _dataSources.isLive(ContentModule.academy)) {
        return const Right(null);
      }

      final row = await _dataSource.getProgramBySlug(slug);
      return Right(row == null ? null : _toEntity(row));
    } catch (e) {
      return Left(SupabaseExceptions.toFailure(e));
    }
  }

  AcademyProgram _toEntity(Map<String, dynamic> row) =>
      AcademyProgramModel.fromRow(row, _locale, SupabaseConfig.defaultLocale);
}

@riverpod
AcademyRepository academyRepository(Ref ref) {
  // watch: changing language rebuilds this provider so the content refetches
  // in the new language along with the interface.
  final locale = ref.watch(localeControllerProvider).languageCode;

  return AcademyRepositoryImpl(
    ref.read(academyRemoteDataSourceProvider),
    ref.read(dataSourceServiceProvider),
    locale,
  );
}
