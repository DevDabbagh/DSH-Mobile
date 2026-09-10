import 'package:dartz/dartz.dart';

import 'package:dsh_mobile/app/core/errors/failures.dart';
import 'package:dsh_mobile/layers/films/domain/entities/film.dart';

abstract class FilmsRepository {
  /// Published films, newest first — the same order and filter the website's
  /// `getFilms()` applies.
  Future<Either<Failure, List<Film>>> getFilms();

  /// One film by its slug. `Right(null)` means the slug is valid but there is
  /// no published film behind it, which the screen shows as "not found"
  /// rather than as an error.
  Future<Either<Failure, Film?>> getFilmBySlug(String slug);
}
