import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:dsh_mobile/app/supabase/supabase_provider.dart';

part 'home_remote_datasource.g.dart';

/// The Home screen's layout, from `page_sections`.
///
/// This file used to be a retrofit client pointing at `/home/sections` on
/// `api.dontskiphumanity.com` — a host that does not exist. Nothing called
/// it; the screen hardcoded its own content. It now reads the same table the
/// website's About and Support pages read (migration 026, widened by 036).
class HomeRemoteDataSource {
  final SupabaseClient _client;

  HomeRemoteDataSource(this._client);

  Future<List<Map<String, dynamic>>> getSections() async {
    final rows = await _client
        .from('page_sections')
        .select()
        .eq('page', 'mobile_home')
        // Filtering here rather than in the app: a disabled section should
        // not travel over the network at all.
        .eq('enabled', true)
        .order('position', ascending: true);

    return List<Map<String, dynamic>>.from(rows);
  }

  /// The header slider, from the row the website's Landing Settings writes.
  ///
  /// `landing_page_config` is a different table from `page_sections` on
  /// purpose — it predates it and the website's landing editor owns it. The
  /// app reads it rather than curating its own carousel, so the seven cards
  /// an editor arranges in Landing Settings are the seven cards the app
  /// shows. `anon` has a read policy on it (migration 002).
  ///
  /// `maybeSingle`: a project that has never opened Landing Settings has no
  /// row, and that is an empty carousel rather than an exception.
  Future<Map<String, dynamic>?> getHeroSlider() async {
    final row = await _client
        .from('landing_page_config')
        .select('enabled, config')
        .eq('section_key', 'hero')
        .maybeSingle();

    return row;
  }
}

@riverpod
HomeRemoteDataSource homeRemoteDataSource(Ref ref) =>
    HomeRemoteDataSource(ref.read(supabaseClientProvider));
