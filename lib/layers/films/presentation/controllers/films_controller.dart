import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:dsh_mobile/app/supabase/data_source_service.dart';
import 'package:dsh_mobile/layers/films/data/repositories/films_repository_impl.dart';
import 'package:dsh_mobile/layers/films/domain/entities/film.dart';

part 'films_controller.g.dart';

/// The Films tab listing.
///
/// A failure is thrown rather than folded away so the screen can offer a
/// retry — unlike onboarding, an empty films list here is a real state
/// ("nothing published yet") and must stay distinguishable from a failure.
// keepAlive: the listing is fetched once and then survives tab switches and
// trips into a film's details. Without it the provider is disposed the
// moment nothing watches it, and coming back re-queries and re-renders every
// card from its placeholder — which reads as the app reloading itself.
@Riverpod(keepAlive: true)
class FilmsList extends _$FilmsList {
  @override
  Future<List<Film>> build() async {
    final result = await ref.watch(filmsRepositoryProvider).getFilms();
    return result.fold((failure) => throw failure, (films) => films);
  }

  /// Pull-to-refresh. Re-reads rather than calling `build()` again, which
  /// would re-register this notifier's watches on every gesture.
  Future<void> refresh() async {
    state = const AsyncValue.loading();

    ref.read(dataSourceServiceProvider).invalidateCache();
    final result = await ref.read(filmsRepositoryProvider).getFilms();

    state = result.fold(
      (failure) => AsyncValue.error(failure, StackTrace.current),
      (films) => AsyncValue.data(films),
    );
  }
}

/// One film, by slug.
///
/// Reuses the already-loaded listing when it holds the film, so opening a card
/// shows content immediately instead of a spinner over data the app has.
@riverpod
Future<Film?> filmBySlug(Ref ref, String slug) async {
  final cached = ref.watch(filmsListProvider).valueOrNull;
  final hit = cached?.where((f) => f.slug == slug);
  if (hit != null && hit.isNotEmpty) return hit.first;

  final result = await ref.watch(filmsRepositoryProvider).getFilmBySlug(slug);
  return result.fold((failure) => throw failure, (film) => film);
}
