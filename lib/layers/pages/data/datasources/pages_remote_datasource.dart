import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:dsh_mobile/app/supabase/supabase_provider.dart';

part 'pages_remote_datasource.g.dart';

class PagesRemoteDataSource {
  final SupabaseClient _client;

  PagesRemoteDataSource(this._client);

  /// Sections for one page, already filtered and ordered by the database.
  ///
  /// `enabled` is filtered here rather than in the app so a disabled section
  /// never crosses the wire — the editor uses it to take a section down, and
  /// down should mean down.
  Future<List<Map<String, dynamic>>> getSections(String page) async {
    final rows = await _client
        .from('page_sections')
        .select()
        .eq('page', page)
        .eq('enabled', true)
        .order('position', ascending: true);

    return List<Map<String, dynamic>>.from(rows);
  }
}

@riverpod
PagesRemoteDataSource pagesRemoteDataSource(Ref ref) =>
    PagesRemoteDataSource(ref.read(supabaseClientProvider));
