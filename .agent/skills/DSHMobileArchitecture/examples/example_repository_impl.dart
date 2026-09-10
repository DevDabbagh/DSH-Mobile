// lib/layers/films/data/repositories/films_repository_impl.dart
//
// Where raw rows become entities and exceptions become Failures.
// This is the ONLY layer that knows about both PostgrestException and Either.

import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:dsh_mobile/app/core/errors/failures.dart';
import 'package:dsh_mobile/app/localization/locale_controller.dart';
import 'package:dsh_mobile/app/supabase/supabase_exceptions.dart';
import 'package:dsh_mobile/layers/films/data/datasources/films_remote_datasource.dart';
import 'package:dsh_mobile/layers/films/data/models/film_model.dart';
import 'package:dsh_mobile/layers/films/domain/entities/film.dart';
import 'package:dsh_mobile/layers/films/domain/repositories/films_repository.dart';

part 'films_repository_impl.g.dart';

class FilmsRepositoryImpl implements FilmsRepository {
  final FilmsRemoteDataSource _dataSource;
  final String _locale;
  final String _defaultLocale;

  FilmsRepositoryImpl(this._dataSource, this._locale, this._defaultLocale);

  @override
  Future<Either<Failure, List<Film>>> getFilms() async {
    try {
      final rows = await _dataSource.getFilms();
      final films = rows
          .map((r) => FilmModel.fromJson(r).toEntity(_locale, _defaultLocale))
          .toList();
      return Right(films);
    } on PostgrestException catch (e) {
      return Left(SupabaseExceptions.toFailure(e));
    } catch (e) {
      // Safety net: a parsing bug must surface as a Failure, not a crash.
      return const Left(ServerFailure('Failed to load films'));
    }
  }

  @override
  Future<Either<Failure, Film>> getFilmBySlug(String slug) async {
    try {
      final row = await _dataSource.getFilmBySlug(slug);
      if (row == null) {
        return const Left(ServerFailure('Film not found', statusCode: 404));
      }
      return Right(FilmModel.fromJson(row).toEntity(_locale, _defaultLocale));
    } on PostgrestException catch (e) {
      return Left(SupabaseExceptions.toFailure(e));
    } catch (e) {
      return const Left(ServerFailure('Failed to load film'));
    }
  }

  @override
  Future<Either<Failure, Unit>> requestTrailerAccess(
    String filmId,
    String email,
  ) async {
    try {
      await _dataSource.requestTrailerAccess(filmId, email);
      return const Right(unit);
    } on PostgrestException catch (e) {
      return Left(SupabaseExceptions.toFailure(e));
    } catch (e) {
      return const Left(ServerFailure('Failed to submit request'));
    }
  }
}

// The provider returns the ABSTRACT type, so the presentation layer never
// depends on the implementation. Note the plain `Ref`.
@riverpod
FilmsRepository filmsRepository(Ref ref) {
  final locale = ref.watch(localeControllerProvider);
  return FilmsRepositoryImpl(
    ref.read(filmsRemoteDataSourceProvider),
    locale.languageCode,
    'en',
  );
}
