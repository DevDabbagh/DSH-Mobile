import 'dart:ui';

// `Ref` comes from here, not from riverpod_annotation — without it the
// generated `isRtl` provider has no type for its parameter.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:dsh_mobile/app/providers/shared_prefs_provider.dart';
import 'package:dsh_mobile/l10n/app_localizations.dart';

part 'locale_controller.g.dart';

/// The language the app is displayed in.
///
/// Two things read this: `MaterialApp.router` for interface strings, and
/// every content repository, which passes the code to `pickLang` so Supabase
/// text comes back in the same language. Because it is a provider, changing
/// it rebuilds the UI and refetches content together — the two can't drift
/// into showing an Arabic interface over English copy.
///
/// keepAlive so the choice survives navigation.
@Riverpod(keepAlive: true)
class LocaleController extends _$LocaleController {
  @override
  Locale build() {
    final saved = ref.read(sharedPrefsHelperProvider).getLocale();
    if (saved != null && _isSupported(saved)) return Locale(saved);

    // No stored choice: follow the phone if we speak its language, otherwise
    // fall back to English.
    final device = PlatformDispatcher.instance.locale.languageCode;
    return _isSupported(device) ? Locale(device) : const Locale('en');
  }

  /// Language codes the app ships translations for.
  ///
  /// Derived from the generated localisations rather than a hand-written
  /// list, so adding an .arb file is enough — nothing here needs editing to
  /// keep the two in step.
  static List<String> get supportedCodes =>
      AppLocalizations.supportedLocales.map((l) => l.languageCode).toList();

  static bool _isSupported(String code) => supportedCodes.contains(code);

  /// Persists the choice so the app opens in the same language next time.
  Future<void> setLocale(String code) async {
    if (!_isSupported(code) || code == state.languageCode) return;

    await ref.read(sharedPrefsHelperProvider).setLocale(code);
    state = Locale(code);
  }
}

/// Whether the current language is written right-to-left.
///
/// Flutter handles direction from the Locale on its own; this is for the few
/// places that need to know explicitly — mirroring an icon, say.
@riverpod
bool isRtl(Ref ref) {
  final code = ref.watch(localeControllerProvider).languageCode;
  return code == 'ar';
}
