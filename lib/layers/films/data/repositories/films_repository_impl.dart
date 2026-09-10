import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:dsh_mobile/app/core/errors/failures.dart';
import 'package:dsh_mobile/app/localization/locale_controller.dart';
import 'package:dsh_mobile/app/supabase/data_source_service.dart';
import 'package:dsh_mobile/app/supabase/supabase_config.dart';
import 'package:dsh_mobile/app/supabase/supabase_exceptions.dart';
import 'package:dsh_mobile/layers/films/data/datasources/films_remote_datasource.dart';
import 'package:dsh_mobile/layers/films/data/models/film_model.dart';
import 'package:dsh_mobile/layers/films/domain/entities/film.dart';
import 'package:dsh_mobile/layers/films/domain/repositories/films_repository.dart';

part 'films_repository_impl.g.dart';

class FilmsRepositoryImpl implements FilmsRepository {
  final FilmsRemoteDataSource _dataSource;
  final DataSourceService _dataSources;
  final String _locale;

  FilmsRepositoryImpl(this._dataSource, this._dataSources, this._locale);

  @override
  Future<Either<Failure, List<Film>>> getFilms() async {
    try {
      // The dashboard can hold films back while the section is being filled
      // in. The website substitutes its bundled placeholders here; the app
      // returns nothing and lets the screen show its empty state, because
      // placeholder films inside a shipped binary read as real ones.
      if (!await _dataSources.isLive(ContentModule.films)) {
        return const Right([]);
      }

      final rows = await _dataSource.getFilms();
      return Right(rows.map(_toEntity).toList());
    } catch (e) {
      return Left(SupabaseExceptions.toFailure(e));
    }
  }

  @override
  Future<Either<Failure, Film?>> getFilmBySlug(String slug) async {
    try {
      if (!await _dataSources.isLive(ContentModule.films)) {
        return const Right(null);
      }

      final row = await _dataSource.getFilmBySlug(slug);
      return Right(row == null ? null : _toEntity(row));
    } catch (e) {
      return Left(SupabaseExceptions.toFailure(e));
    }
  }

  Film _toEntity(Map<String, dynamic> row) =>
      FilmModel.fromRow(row, _locale, SupabaseConfig.defaultLocale);
}

@riverpod
FilmsRepository filmsRepository(Ref ref) {
  // watch: changing language rebuilds this provider so the content refetches
  // in the new language along with the interface.
  final locale = ref.watch(localeControllerProvider).languageCode;

  return FilmsRepositoryImpl(
    ref.read(filmsRemoteDataSourceProvider),
    ref.read(dataSourceServiceProvider),
    locale,
  );
}
