import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:dsh_mobile/app/core/errors/failures.dart';
import 'package:dsh_mobile/app/localization/locale_controller.dart';
import 'package:dsh_mobile/app/supabase/data_source_service.dart';
import 'package:dsh_mobile/app/supabase/supabase_config.dart';
import 'package:dsh_mobile/app/supabase/supabase_exceptions.dart';
import 'package:dsh_mobile/layers/studio/data/datasources/studio_remote_datasource.dart';
import 'package:dsh_mobile/layers/studio/data/models/studio_project_model.dart';
import 'package:dsh_mobile/layers/studio/domain/entities/studio_project.dart';
import 'package:dsh_mobile/layers/studio/domain/repositories/studio_repository.dart';

part 'studio_repository_impl.g.dart';

class StudioRepositoryImpl implements StudioRepository {
  final StudioRemoteDataSource _dataSource;
  final DataSourceService _dataSources;
  final String _locale;

  StudioRepositoryImpl(this._dataSource, this._dataSources, this._locale);

  @override
  Future<Either<Failure, List<StudioProject>>> getProjects() async {
    try {
      if (!await _dataSources.isLive(ContentModule.studio)) {
        return const Right([]);
      }

      final rows = await _dataSource.getProjects();
      return Right(rows.map(_toEntity).toList());
    } catch (e) {
      return Left(SupabaseExceptions.toFailure(e));
    }
  }

  @override
  Future<Either<Failure, StudioProject?>> getProjectBySlug(String slug) async {
    try {
      if (!await _dataSources.isLive(ContentModule.studio)) {
        return const Right(null);
      }

      final row = await _dataSource.getProjectBySlug(slug);
      return Right(row == null ? null : _toEntity(row));
    } catch (e) {
      return Left(SupabaseExceptions.toFailure(e));
    }
  }

  StudioProject _toEntity(Map<String, dynamic> row) =>
      StudioProjectModel.fromRow(row, _locale, SupabaseConfig.defaultLocale);
}

@riverpod
StudioRepository studioRepository(Ref ref) {
  final locale = ref.watch(localeControllerProvider).languageCode;

  return StudioRepositoryImpl(
    ref.read(studioRemoteDataSourceProvider),
    ref.read(dataSourceServiceProvider),
    locale,
  );
}
