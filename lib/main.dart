import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dsh_mobile/app.dart';
import 'package:dsh_mobile/app/core/debug/net_logger.dart';
import 'package:dsh_mobile/app/providers/shared_prefs_helper.dart';
import 'package:dsh_mobile/app/providers/shared_prefs_provider.dart';
import 'package:dsh_mobile/app/push/push_service.dart';
import 'package:dsh_mobile/app/supabase/supabase_config.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Supabase must be ready before any provider touches it. It's a local
  // setup call, not a network round-trip, so it doesn't delay first paint.
  await Supabase.initialize(
    url: SupabaseConfig.url,
    // Renamed upstream; `anonKey` still works but is deprecated.
    publishableKey: SupabaseConfig.anonKey,
    // Every request the SDK makes, printed — in debug only. Null in release,
    // which makes the SDK use its own client and leaves no logging code in
    // the shipped binary. See NetLogger for why it lives here rather than in
    // the datasources.
    httpClient: NetLogger.maybeWrap(),
    // The SDK's own chatter: auth state transitions, token refresh, realtime.
    // Useful alongside the request log, and noise in a release build.
    debug: kDebugMode,
  );

  // Auth transitions, which are not HTTP requests and so do not show up in
  // NetLogger. A session that expires or a sign-in that silently does not
  // stick is visible here and almost nowhere else.
  if (kDebugMode) {
    Supabase.instance.client.auth.onAuthStateChange.listen((state) {
      developer.log(
        '${state.event.name}  user=${state.session?.user.email ?? 'none'}',
        name: 'supabase.auth',
      );
    });
  }

  // Initialize SharedPreferences (needed by ProviderScope override).
  final prefs = await SharedPreferences.getInstance();
  final sharedPrefsHelper = SharedPrefsHelper(prefs);

  // Push. A no-op when Firebase is not configured — the app carries on
  // without notifications rather than refusing to start.
  await PushService.instance.init();

  runApp(
    ProviderScope(
      overrides: [
        sharedPrefsHelperProvider.overrideWithValue(sharedPrefsHelper),
      ],
      child: const DshApp(),
    ),
  );
}
