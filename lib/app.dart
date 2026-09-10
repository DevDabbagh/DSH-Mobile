import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:dsh_mobile/app/localization/locale_controller.dart';
import 'package:dsh_mobile/app/push/push_service.dart';
import 'package:dsh_mobile/app/router/app_router.dart';
import 'package:dsh_mobile/app/theme/app_theme.dart';
import 'package:dsh_mobile/l10n/app_localizations.dart';
import 'package:dsh_mobile/layers/notifications/presentation/controllers/notifications_controller.dart';

class DshApp extends ConsumerStatefulWidget {
  const DshApp({super.key});

  @override
  ConsumerState<DshApp> createState() => _DshAppState();
}

class _DshAppState extends ConsumerState<DshApp> {
  StreamSubscription<String>? _pushTaps;

  @override
  void initState() {
    super.initState();

    // A tapped notification names an in-app route. Handled here, at the one
    // point that outlives every screen: PushService has no business knowing
    // about GoRouter, and no individual page is guaranteed to be mounted
    // when the tap arrives — least of all on a cold start.
    _pushTaps = PushService.instance.onTapRoute.listen((route) {
      if (!mounted) return;
      try {
        ref.read(appRouterProvider).push(route);
      } catch (_) {
        // A route from an older or newer build that this one doesn't have.
        // Opening the app is still the right outcome; crashing is not.
      }
    });
  }

  @override
  void dispose() {
    _pushTaps?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Keeps push_devices in step with who is signed in and which language
    // they read. Watched here so it is alive for the app's whole lifetime.
    ref.watch(pushRegistrationProvider);

    return ScreenUtilInit(
      // Must match the Figma frames, which are all 393 wide — OnBoarding,
      // Home, Films, Studio, Episode Details, every one of them.
      //
      // This was 428 (iPhone 14 Pro Max). Every `.sp` and `.w` in the app was
      // therefore scaled by 393/428, so a value typed straight from Figma
      // rendered about 8% small — uniformly, across every screen, which is
      // exactly why it read as "slightly off" rather than as an obvious bug.
      designSize: const Size(393, 852), // iPhone 14/15 — the Figma frame
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        final goRouter = ref.watch(appRouterProvider);
        final theme = ref.watch(darkThemeProvider); // DSH uses dark-first
        final locale = ref.watch(localeControllerProvider);

        return MaterialApp.router(
          title: "Don't Skip Humanity",
          theme: theme,
          themeMode: ThemeMode.dark,
          routerConfig: goRouter,
          debugShowCheckedModeBanner: false,

          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],

          // Read from the generated localisations rather than listed by hand.
          // A hand-written list silently drops a language: app_pt.arb was
          // translated and generated, but Portuguese was missing here, so it
          // could never be selected no matter what the phone was set to.
          supportedLocales: AppLocalizations.supportedLocales,

          // The user's choice wins over the device language.
          locale: locale,
        );
      },
    );
  }
}
