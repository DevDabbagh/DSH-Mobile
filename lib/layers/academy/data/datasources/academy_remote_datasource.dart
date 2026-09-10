import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:dsh_mobile/app/supabase/supabase_provider.dart';

part 'academy_remote_datasource.g.dart';

/// Programme plus its downloadable resources in one round trip — the same
/// select string the website uses in `getPrograms()`.
const _programSelect = '*, academy_resources(*)';

class AcademyRemoteDataSource {
  final SupabaseClient _client;

  AcademyRemoteDataSource(this._client);

  Future<List<Map<String, dynamic>>> getPrograms() async {
    // `status = published` is also enforced by RLS; stating it here keeps the
    // query readable and identical to the website's.
    final rows = await _client
        .from('academy_programs')
        .select(_programSelect)
        .eq('status', 'published')
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(rows);
  }

  /// `maybeSingle` rather than `single`: a slug with no row is a 404 screen,
  /// not an exception.
  Future<Map<String, dynamic>?> getProgramBySlug(String slug) async {
    final row = await _client
        .from('academy_programs')
        .select(_programSelect)
        .eq('slug', slug)
        .eq('status', 'published')
        .maybeSingle();

    return row;
  }
}

@riverpod
AcademyRemoteDataSource academyRemoteDataSource(Ref ref) =>
    AcademyRemoteDataSource(ref.read(supabaseClientProvider));
