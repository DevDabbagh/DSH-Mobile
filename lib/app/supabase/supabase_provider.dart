import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'supabase_provider.g.dart';

/// The app-wide Supabase client.
///
/// `Supabase.initialize()` runs once in main.dart; this just hands out the
/// singleton so datasources take it by constructor rather than reaching for
/// a global, which keeps them testable.
@Riverpod(keepAlive: true)
SupabaseClient supabaseClient(Ref ref) => Supabase.instance.client;
