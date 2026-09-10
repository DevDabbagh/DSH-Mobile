// lib/layers/films/domain/repositories/films_repository.dart
//
// Domain contract. Pure Dart — no Flutter, no JSON, no Supabase.
// ALWAYS return Either<Failure, T>.

import 'package:dartz/dartz.dart';

import 'package:dsh_mobile/app/core/errors/failures.dart';
import 'package:dsh_mobile/layers/films/domain/entities/film.dart';

abstract class FilmsRepository {
  Future<Either<Failure, List<Film>>> getFilms();

  Future<Either<Failure, Film>> getFilmBySlug(String slug);

  /// Use `Unit` (dartz) rather than `void` for operations with no return value,
  /// so the Either type stays well-formed and `fold` still works.
  Future<Either<Failure, Unit>> requestTrailerAccess(String filmId, String email);
}
