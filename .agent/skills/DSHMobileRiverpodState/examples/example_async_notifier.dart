// lib/layers/films/presentation/controllers/films_controller.dart
//
// The controller is where Either<Failure, T> becomes AsyncValue<T>.
// Nothing above this layer should ever see a Failure object.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:dsh_mobile/layers/films/data/repositories/films_repository_impl.dart';
import 'package:dsh_mobile/layers/films/domain/entities/film.dart';

part 'films_controller.g.dart';

@riverpod
class FilmsController extends _$FilmsController {
  /// In build(), THROW on the Left. Riverpod turns it into AsyncError for us,
  /// with a real stack trace — cleaner than assembling AsyncError by hand.
  @override
  FutureOr<List<Film>> build() async {
    final result = await ref.read(filmsRepositoryProvider).getFilms();
    return result.fold(
      (failure) => throw Exception(failure.message),
      (films) => films,
    );
  }

  /// In a refresh, set state from the fold directly.
  /// copyWithPrevious keeps the current list on screen while reloading,
  /// instead of flashing back to a shimmer.
  Future<void> refresh() async {
    state = const AsyncLoading<List<Film>>().copyWithPrevious(state);

    final result = await ref.read(filmsRepositoryProvider).getFilms();
    state = result.fold(
      (failure) => AsyncError(failure.message, StackTrace.current),
      (films) => AsyncData(films),
    );
  }
}

/// ── Mutation pattern ──────────────────────────────────────────────
/// State is void because the caller only cares whether it succeeded.
/// `ref.listen` in the UI drives LoadingOverlay off the isLoading flag.
@riverpod
class TrailerAccessController extends _$TrailerAccessController {
  @override
  FutureOr<void> build() {}

  Future<void> submit(String filmId, String email) async {
    state = const AsyncLoading();

    final result = await ref
        .read(filmsRepositoryProvider)
        .requestTrailerAccess(filmId, email);

    // Set state ONCE from the fold. Never set AsyncError and then rethrow —
    // that makes ref.listen fire the error handling twice.
    state = result.fold(
      (failure) => AsyncError(failure.message, StackTrace.current),
      (_) => const AsyncData(null),
    );
  }
}
