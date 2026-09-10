// lib/layers/films/data/datasources/films_remote_datasource.dart
//
// Supabase datasource. This is the DEFAULT for every DSH content table.
// Dio + Retrofit are reserved for third-party APIs (Stripe, etc.).
//
// The datasource returns RAW rows. Parsing into models belongs to the
// repository, and so does catching PostgrestException.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:dsh_mobile/app/supabase/supabase_provider.dart';

part 'films_remote_datasource.g.dart';

class FilmsRemoteDataSource {
  final SupabaseClient _client;

  FilmsRemoteDataSource(this._client);

  Future<List<Map<String, dynamic>>> getFilms() async {
    final rows = await _client
        .from('films')
        .select()
        .eq('status', 'published')
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(rows);
  }

  /// `maybeSingle()` returns null instead of throwing when no row matches —
  /// a missing slug is a normal outcome, not an error.
  Future<Map<String, dynamic>?> getFilmBySlug(String slug) async {
    return await _client
        .from('films')
        .select()
        .eq('slug', slug)
        .eq('status', 'published')
        .maybeSingle();
  }
}

// Note the plain `Ref` type — never the generated `FilmsRemoteDataSourceRef`.
@riverpod
FilmsRemoteDataSource filmsRemoteDataSource(Ref ref) =>
    FilmsRemoteDataSource(ref.read(supabaseClientProvider));
