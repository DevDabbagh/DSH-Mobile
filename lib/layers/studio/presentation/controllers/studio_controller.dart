import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:dsh_mobile/app/supabase/data_source_service.dart';
import 'package:dsh_mobile/layers/studio/data/repositories/studio_repository_impl.dart';
import 'package:dsh_mobile/layers/studio/domain/entities/studio_project.dart';

part 'studio_controller.g.dart';

/// The Studio tab listing.
// keepAlive, for the same reason as FilmsList: a trip into a project and
// back should not re-fetch the catalogue.
@Riverpod(keepAlive: true)
class StudioList extends _$StudioList {
  @override
  Future<List<StudioProject>> build() async {
    final result = await ref.watch(studioRepositoryProvider).getProjects();
    return result.fold((failure) => throw failure, (projects) => projects);
  }

  /// Pull-to-refresh. Re-reads rather than calling `build()` again, which
  /// would re-register this notifier's watches on every gesture.
  Future<void> refresh() async {
    state = const AsyncValue.loading();

    ref.read(dataSourceServiceProvider).invalidateCache();
    final result = await ref.read(studioRepositoryProvider).getProjects();

    state = result.fold(
      (failure) => AsyncValue.error(failure, StackTrace.current),
      (projects) => AsyncValue.data(projects),
    );
  }
}

/// One project with its episodes, by slug — served from the listing when it is
/// already loaded.
@riverpod
Future<StudioProject?> studioProjectBySlug(Ref ref, String slug) async {
  final cached = ref.watch(studioListProvider).valueOrNull;
  final hit = cached?.where((p) => p.slug == slug);
  if (hit != null && hit.isNotEmpty) return hit.first;

  final result =
      await ref.watch(studioRepositoryProvider).getProjectBySlug(slug);
  return result.fold((failure) => throw failure, (project) => project);
}

/// One episode, addressed by its project's slug and its own.
///
/// The episode page is always reached through a project, and episodes arrive
/// joined to it — so this resolves the project once and reads the episode out
/// of it rather than querying `studio_episodes` separately.
@riverpod
Future<StudioEpisode?> studioEpisode(
  Ref ref,
  String projectSlug,
  String episodeSlug,
) async {
  final project =
      await ref.watch(studioProjectBySlugProvider(projectSlug).future);
  return project?.episodeBySlug(episodeSlug);
}
