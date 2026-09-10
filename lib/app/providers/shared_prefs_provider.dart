import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:dsh_mobile/app/providers/shared_prefs_helper.dart';

part 'shared_prefs_provider.g.dart';

/// Initialized in main.dart and overridden via ProviderScope.
@Riverpod(keepAlive: true)
SharedPrefsHelper sharedPrefsHelper(Ref ref) {
  throw UnimplementedError(
    'sharedPrefsHelperProvider must be overridden in ProviderScope',
  );
}
