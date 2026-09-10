import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:dsh_mobile/app/supabase/supabase_provider.dart';

part 'onboarding_remote_datasource.g.dart';

class OnboardingRemoteDataSource {
  final SupabaseClient _client;

  OnboardingRemoteDataSource(this._client);

  /// Raw rows, in display order.
  ///
  /// No `.eq('enabled', true)` here — the RLS policy on the table already
  /// hides disabled rows from the anon key, and repeating the filter in the
  /// client would suggest it is the thing enforcing it.
  Future<List<Map<String, dynamic>>> getSlides() async {
    final rows = await _client
        .from('mobile_onboarding_slides')
        .select()
        .order('sort_order', ascending: true);

    return List<Map<String, dynamic>>.from(rows);
  }
}

@riverpod
OnboardingRemoteDataSource onboardingRemoteDataSource(Ref ref) =>
    OnboardingRemoteDataSource(ref.read(supabaseClientProvider));
