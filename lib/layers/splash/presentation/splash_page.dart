import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'package:dsh_mobile/app/config/app_colors.dart';
import 'package:dsh_mobile/app/providers/shared_prefs_provider.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  late VideoPlayerController _controller;
  bool _isVideoInitialized = false;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      _controller =
          VideoPlayerController.asset('assets/videos/ic_splash_logo.mp4');
      await _controller.initialize();

      if (!mounted) return;
      setState(() {
        _isVideoInitialized = true;
      });
      _controller.play();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        FlutterNativeSplash.remove();
      });

      // Fallback timer: force navigation after 4 seconds if the video hangs or is slow to start
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) _navigate();
      });

      // Listen for video completion
      _controller.addListener(() {
        if (_controller.value.isInitialized) {
          final position = _controller.value.position;
          final duration = _controller.value.duration;
          // When the video reaches the end
          if (duration > Duration.zero && position >= duration) {
            if (mounted) _navigate();
          }
        }
      });
    } catch (e) {
      // debugPrint rather than print: analysis_options bans print, and this
      // should not reach a release build's console.
      debugPrint('Splash video failed to initialise: $e');
      // Fallback if video fails to load (e.g. on emulators)
      FlutterNativeSplash.remove();
      if (mounted) _navigate();
    }
  }

  void _navigate() {
    if (!mounted || _navigated) return;
    _navigated = true;

    // Onboarding is first-launch only. After that the router's redirect
    // decides between Home and Login based on the restored session, so this
    // just needs to get out of the way.
    final hasSeenOnboarding =
        ref.read(sharedPrefsHelperProvider).hasSeenOnboarding();

    context.go(hasSeenOnboarding ? '/home' : '/onboarding');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.brandBlack,
      body: _isVideoInitialized
          ? SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
