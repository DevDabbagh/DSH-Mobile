import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:dsh_mobile/app/core/errors/failures.dart';
import 'package:dsh_mobile/app/localization/locale_controller.dart';
import 'package:dsh_mobile/app/supabase/data_source_service.dart';
import 'package:dsh_mobile/app/supabase/lang_helper.dart';
import 'package:dsh_mobile/app/supabase/media_url.dart';
import 'package:dsh_mobile/app/supabase/supabase_config.dart';
import 'package:dsh_mobile/app/supabase/supabase_exceptions.dart';
import 'package:dsh_mobile/app/supabase/supabase_provider.dart';
import 'package:dsh_mobile/layers/impact/domain/entities/impact_stat.dart';
import 'package:dsh_mobile/layers/impact/domain/entities/impact_story.dart';
import 'package:dsh_mobile/layers/impact/domain/repositories/impact_repository.dart';

part 'impact_repository_impl.g.dart';

/// Datasource and repository in one file.
///
/// `impact_stats` is four columns and one query with no joins, no filters and
/// no language resolution. Splitting it across the usual three files would be
/// ceremony around a single `select` — the separation earns its keep on
/// films and studio, and does not here.
class ImpactRepositoryImpl implements ImpactRepository {
  final SupabaseClient _client;
  final DataSourceService _dataSources;

  /// Only the stories need it — `impact_stats.label` is a plain TEXT column.
  final String _locale;

  ImpactRepositoryImpl(this._client, this._dataSources, this._locale);

  @override
  Future<Either<Failure, List<ImpactStat>>> getStats() async {
    try {
      if (!await _dataSources.isLive(ContentModule.impact)) {
        return const Right([]);
      }

      final rows = await _client
          .from('impact_stats')
          .select()
          .order('created_at', ascending: false);

      final stats = List<Map<String, dynamic>>.from(rows)
          .map((r) => ImpactStat(
                id: r['id']?.toString() ?? '',
                label: r['label']?.toString() ?? '',
                value: (r['value'] as num?)?.toDouble() ?? 0,
                suffix: r['suffix']?.toString() ?? '',
                imageUrl: resolveMediaUrl(r['image_url']),
                icon: r['icon']?.toString() ?? '',
              ))
          // A figure with no label says nothing; a label with no figure says
          // less. Both are half-finished rows, not content.
          .where((s) => s.label.trim().isNotEmpty && s.value > 0)
          .toList();

      return Right(stats);
    } catch (e) {
      return Left(SupabaseExceptions.toFailure(e));
    }
  }

  @override
  Future<Either<Failure, List<ImpactStory>>> getStories() async {
    try {
      if (!await _dataSources.isLive(ContentModule.impact)) {
        return const Right([]);
      }

      // `status` is filtered here rather than trusted to RLS: the anon policy
      // on this table lets a guest read every row, drafts included, and a
      // half-written story on the Impact screen is exactly the thing an
      // editor assumed was still private.
      final rows = await _client
          .from('impact_stories')
          .select()
          .eq('status', 'published')
          .order('created_at', ascending: false);

      String text(dynamic v) =>
          pickLang(v, _locale, SupabaseConfig.defaultLocale);

      final stories = List<Map<String, dynamic>>.from(rows)
          .map((r) => ImpactStory(
                id: r['id']?.toString() ?? '',
                title: text(r['title']),
                description: text(r['description']),
                imageUrl: resolveMediaUrl(r['image_url']),
                linkedFilm: r['linked_film']?.toString() ?? '',
              ))
          // A card with no title is a row someone started and left.
          .where((s) => s.title.trim().isNotEmpty)
          .toList();

      return Right(stories);
    } catch (e) {
      return Left(SupabaseExceptions.toFailure(e));
    }
  }
}

@riverpod
ImpactRepository impactRepository(Ref ref) {
  // watch, not read: switching language rebuilds this so the stories refetch
  // in the new language along with the interface.
  final locale = ref.watch(localeControllerProvider).languageCode;

  return ImpactRepositoryImpl(
    ref.read(supabaseClientProvider),
    ref.read(dataSourceServiceProvider),
    locale,
  );
}

/// The Impact rail's figures. keepAlive, like the other content lists.
@Riverpod(keepAlive: true)
Future<List<ImpactStat>> impactStats(Ref ref) async {
  final result = await ref.watch(impactRepositoryProvider).getStats();
  return result.fold((failure) => throw failure, (stats) => stats);
}

/// The Impact screen's stories.
@Riverpod(keepAlive: true)
Future<List<ImpactStory>> impactStories(Ref ref) async {
  final result = await ref.watch(impactRepositoryProvider).getStories();
  return result.fold((failure) => throw failure, (stories) => stories);
}
