import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:dsh_mobile/app/supabase/data_source_service.dart';
import 'package:dsh_mobile/layers/academy/data/repositories/academy_repository_impl.dart';
import 'package:dsh_mobile/layers/academy/domain/entities/academy_program.dart';

part 'academy_controller.g.dart';

/// The Academy tab listing.
///
/// A failure is thrown rather than folded away so the screen can offer a
/// retry — an empty list here is a real state ("nothing published yet") and
/// has to stay distinguishable from a failure.
// keepAlive, like Films and Studio: the listing is fetched once and survives
// tab switches. Without it the provider is disposed the moment nothing
// watches it, and coming back re-queries and re-renders every card from its
// placeholder — which reads as the app reloading itself.
@Riverpod(keepAlive: true)
class AcademyPrograms extends _$AcademyPrograms {
  @override
  Future<List<AcademyProgram>> build() async {
    final result = await ref.watch(academyRepositoryProvider).getPrograms();
    return result.fold((failure) => throw failure, (programs) => programs);
  }

  /// Pull-to-refresh. Re-reads rather than calling `build()` again, which
  /// would re-register this notifier's watches on every gesture.
  Future<void> refresh() async {
    state = const AsyncValue.loading();

    // Clears the 10-second data-switcher cache too, so flipping the module
    // to live in the dashboard shows up on the next pull rather than after
    // an arbitrary wait.
    ref.read(dataSourceServiceProvider).invalidateCache();
    final result = await ref.read(academyRepositoryProvider).getPrograms();

    state = result.fold(
      (failure) => AsyncValue.error(failure, StackTrace.current),
      (programs) => AsyncValue.data(programs),
    );
  }
}

/// One programme, by slug.
///
/// Reuses the already-loaded listing when it holds the programme, so opening
/// a card shows content immediately instead of a spinner over data the app
/// already has.
@riverpod
Future<AcademyProgram?> academyProgramBySlug(Ref ref, String slug) async {
  final cached = ref.watch(academyProgramsProvider).valueOrNull;
  final hit = cached?.where((p) => p.slug == slug);
  if (hit != null && hit.isNotEmpty) return hit.first;

  final result =
      await ref.watch(academyRepositoryProvider).getProgramBySlug(slug);
  return result.fold((failure) => throw failure, (program) => program);
}
