import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dsh_mobile/app.dart';
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
  );

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
