import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:dsh_mobile/app/supabase/supabase_provider.dart';

part 'films_remote_datasource.g.dart';

/// Every joined table the film screens read, in one round trip — the same
/// select string the website uses in `getFilms()`.
const _filmSelect = '*, film_festivals(*), film_press_quotes(*), '
    'film_screenings(*)';

class FilmsRemoteDataSource {
  final SupabaseClient _client;

  FilmsRemoteDataSource(this._client);

  Future<List<Map<String, dynamic>>> getFilms() async {
    // `status = published` is also enforced by RLS; stating it here keeps the
    // query readable and identical to the website's.
    final rows = await _client
        .from('films')
        .select(_filmSelect)
        .eq('status', 'published')
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(rows);
  }

  /// `maybeSingle` rather than `single`: a slug with no row is a 404 screen,
  /// not an exception.
  Future<Map<String, dynamic>?> getFilmBySlug(String slug) async {
    final row = await _client
        .from('films')
        .select(_filmSelect)
        .eq('slug', slug)
        .eq('status', 'published')
        .maybeSingle();

    return row;
  }
}

@riverpod
FilmsRemoteDataSource filmsRemoteDataSource(Ref ref) =>
    FilmsRemoteDataSource(ref.read(supabaseClientProvider));
