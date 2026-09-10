import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:dsh_mobile/app/supabase/supabase_provider.dart';

part 'studio_remote_datasource.g.dart';

/// Episodes live in their own table (`studio_episodes`), not in a JSONB
/// column, so they come in as a join — same select string as the website.
const _studioSelect = '*, studio_episodes(*), studio_platform_links(*)';

class StudioRemoteDataSource {
  final SupabaseClient _client;

  StudioRemoteDataSource(this._client);

  Future<List<Map<String, dynamic>>> getProjects() async {
    final rows = await _client
        .from('studio_items')
        .select(_studioSelect)
        .eq('status', 'published')
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(rows);
  }

  Future<Map<String, dynamic>?> getProjectBySlug(String slug) async {
    final row = await _client
        .from('studio_items')
        .select(_studioSelect)
        .eq('slug', slug)
        .eq('status', 'published')
        .maybeSingle();

    return row;
  }
}

@riverpod
StudioRemoteDataSource studioRemoteDataSource(Ref ref) =>
    StudioRemoteDataSource(ref.read(supabaseClientProvider));
